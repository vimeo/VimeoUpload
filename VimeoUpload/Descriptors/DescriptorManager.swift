//
//  Uploader.swift
//  VIMUpload
//
//  Created by Alfred Hanssen on 10/3/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

enum DescriptorManagerNotification: String
{
    case DescriptorWillStart = "DescriptorWillStartNotification"
    case DescriptorDidFail = "DescriptorDidFailNotification"
    case DescriptorDidSucceed = "DescriptorDidSucceedNotification"
    case SessionDidBecomeInvalid = "SessionDidBecomeInvalidNotification"
}

class DescriptorManager
{
    private static let DescriptorsArchiveKey = "descriptors"
    
    // DummyTempDirectoryURL is necessary to address AFNetworking and Swift 2 compatibility issues,
    // See this issue: https://github.com/AFNetworking/AFNetworking/issues/3104 [AH] 10/28/2015
    
    private static let DummyTempDirectoryURL = NSURL(string: NSTemporaryDirectory())!

    private var sessionManager: AFURLSessionManager
    private var descriptors = Set<Descriptor>()
    private var archiver = KeyedArchiver(basePath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
    private weak var delegate: DescriptorManagerDelegate?
    
    private let synchronizationQueue = dispatch_queue_create("descriptor_manager.synchronization_queue", DISPATCH_QUEUE_SERIAL)

    var backgroundEventsCompletionHandler: VoidBlock?

    // MARK: Initialization
    
    convenience init(sessionManager: AFURLSessionManager)
    {
        self.init(sessionManager: sessionManager, delegate: nil)
    }
    
    init(sessionManager: AFURLSessionManager, delegate: DescriptorManagerDelegate?)
    {
        self.sessionManager = sessionManager
        self.delegate = delegate

        // We must load the descriptors before we set the sessionBlocks,
        // Otherwise the blocks will be called before we have a list of descriptors to reconcile with [AH] 10/28/ 2015
        
        self.loadDescriptors()

        self.delegate?.didLoadDescriptors(self.descriptors.count)

        self.setupSessionBlocks()
    }

    // MARK: Setup
    
    private func loadDescriptors()
    {
        if let descriptors = self.archiver.loadObjectForKey(DescriptorManager.DescriptorsArchiveKey) as? Set<Descriptor>
        {
            for descriptor in descriptors
            {
                descriptor.didLoadFromCache(self.sessionManager)
            }
            
            self.descriptors = descriptors
        }
    }
    
    private func setupSessionBlocks()
    {
        // Because we're using a background session we never have cause to invalidate the session,
        // Which means that if this block is called it's likely due to an unrecoverable error,
        // So we respond by clearing the descriptors set, returning to a blank slate. [AH] 10/28/2015
        
        self.sessionManager.setSessionDidBecomeInvalidBlock { [weak self] (session, error) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            dispatch_sync(strongSelf.synchronizationQueue, { [weak self] () -> Void in

                guard let strongSelf = self else
                {
                    return
                }

                strongSelf.descriptors.removeAll()
                strongSelf.archiver.saveObject(strongSelf.descriptors, key: DescriptorManager.DescriptorsArchiveKey)

                strongSelf.delegate?.sessionDidBecomeInvalid(error)
                
                NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.SessionDidBecomeInvalid.rawValue, object: error)
            })
        }
        
        // This block should return an optional NSURL but in AFNetworking 2.6.1 this is not the case
        // See link to Github issue above [AH] 10/28/2015
        
        self.sessionManager.setDownloadTaskDidFinishDownloadingBlock { [weak self] (session, task, url) -> NSURL in

            guard let strongSelf = self else
            {
                return DescriptorManager.DummyTempDirectoryURL
            }

            var destination = DescriptorManager.DummyTempDirectoryURL

            dispatch_sync(strongSelf.synchronizationQueue, { [weak self] () -> Void in

                let strongSelf = self!

                guard let descriptor = strongSelf.descriptorForTask(task) else
                {
                    return
                }

                strongSelf.delegate?.downloadTaskDidFinishDownloading(task.taskDescription, descriptorIdentifier: descriptor.identifier)

                if let url = descriptor.taskDidFinishDownloading(strongSelf.sessionManager, task: task, url: url)
                {
                    destination = url
                }
                
                strongSelf.archiver.saveObject(strongSelf.descriptors, key: DescriptorManager.DescriptorsArchiveKey)
            })
            
            return destination
        }
        
        self.sessionManager.setTaskDidCompleteBlock { [weak self] (session, task, error) -> Void in

            guard let strongSelf = self else
            {
                return
            }

            dispatch_sync(strongSelf.synchronizationQueue, { [weak self] () -> Void in

                guard let strongSelf = self else
                {
                    return
                }

                guard let descriptor = strongSelf.descriptorForTask(task) else
                {
                    return
                }

                strongSelf.delegate?.taskDidComplete(task.taskDescription, descriptorIdentifier: descriptor.identifier, error: error)

                descriptor.taskDidComplete(strongSelf.sessionManager, task: task, error: error)

                strongSelf.archiver.saveObject(strongSelf.descriptors, key: DescriptorManager.DescriptorsArchiveKey)
                
                if descriptor.state == State.Finished
                {
                    strongSelf.descriptors.remove(descriptor)
                    strongSelf.archiver.saveObject(strongSelf.descriptors, key: DescriptorManager.DescriptorsArchiveKey)
                    
                    if descriptor.error != nil
                    {
                        strongSelf.delegate?.descriptorDidFail(descriptor.identifier)
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidFail.rawValue, object: descriptor.identifier)
                    }
                    else
                    {
                        strongSelf.delegate?.descriptorDidSucceed(descriptor.identifier)

                        NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidSucceed.rawValue, object: descriptor.identifier)
                    }
                }
            })
        }
        
        self.sessionManager.setDidFinishEventsForBackgroundURLSessionBlock { [weak self] (session) -> Void in

            guard let strongSelf = self else
            {
                return
            }

            if let backgroundEventsCompletionHandler = strongSelf.backgroundEventsCompletionHandler
            {
                strongSelf.delegate?.didFinishEventsForBackgroundSession()
                
                // This completionHandler must be called on the main thread
                backgroundEventsCompletionHandler()
                strongSelf.backgroundEventsCompletionHandler = nil
            }
        }
    }
    
    // MARK: Public API
    
    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: VoidBlock) -> Bool
    {
        guard identifier == self.sessionManager.session.configuration.identifier else
        {
            return false
        }
        
        self.delegate?.willHandleEventsForBackgroundSession()

        self.backgroundEventsCompletionHandler = completionHandler
        
        return true
    }
    
    func addDescriptor(descriptor: Descriptor) throws
    {
        dispatch_async(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.descriptors.insert(descriptor)
            strongSelf.archiver.saveObject(strongSelf.descriptors, key: DescriptorManager.DescriptorsArchiveKey)

            strongSelf.delegate?.descriptorWillStart(descriptor.identifier)

            NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorWillStart.rawValue, object: descriptor.identifier)
            
            descriptor.start(strongSelf.sessionManager)
            strongSelf.archiver.saveObject(strongSelf.descriptors, key: DescriptorManager.DescriptorsArchiveKey)
        })
    }
    
    func cancelDescriptorForIdentifier(identifier: String)
    {
        dispatch_async(self.synchronizationQueue, { [weak self] () -> Void in

            guard let strongSelf = self else
            {
                return
            }
            
            if let descriptor = strongSelf.descriptorForIdentifier(identifier)
            {
                for task in strongSelf.sessionManager.tasks
                {
                    if task.taskIdentifier == descriptor.currentTaskIdentifier
                    {                        
                        task.cancel()// TODO: move this into the descriptor's cancel method
                        break
                    }
                }
            }
        })
    }
    
    func cancelAllDescriptors()
    {
        dispatch_async(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            for task in strongSelf.sessionManager.tasks
            {
                task.cancel()
            }
        })
    }
    
    // MARK: Private API
        
    private func descriptorForTask(task: NSURLSessionTask) -> Descriptor?
    {
        var result: Descriptor?
                
        for currentDescriptor in self.descriptors
        {
            if currentDescriptor.currentTaskIdentifier == task.taskIdentifier
            {
                result = currentDescriptor
                break
            }
        }
        
        // If the descriptor is not found then the session.tasks and self.descriptors are out of sync
        // This is a major problem [AH] 10/29/2015
        if result == nil
        {
            self.delegate?.descriptorForTaskNotFound(task.taskDescription)
        }
        
        return result
    }

    private func descriptorForIdentifier(identifier: String) -> Descriptor?
    {
        var result: Descriptor?
        
        for currentDescriptor in self.descriptors
        {
            if currentDescriptor.identifier == identifier
            {
                result = currentDescriptor
                break
            }
        }
        
        // At present, this method is only called during a descriptor cancellation,
        // If the descriptor is not found then perhaps it completed before the cancellation, no big deal,
        // Logging this however just to keep an eye on it [AH] 10/29/2015
        if result == nil
        {
            self.delegate?.descriptorForIdentifierNotFound(identifier)
        }

        return result
    }
}
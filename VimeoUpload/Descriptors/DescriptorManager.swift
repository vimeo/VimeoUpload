//
//  DescriptorManager.swift
//  VimeoUpload
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

typealias TestBlock = (descriptor: Descriptor) -> Bool

class DescriptorManager
{
    private static let DescriptorsArchiveKey = "descriptors"
    private static let QueueName = "descriptor_manager.synchronization_queue"
    
    // MARK:
    
    private var sessionManager: AFURLSessionManager
    private let name: String

    // MARK:
    
    private var descriptors = Set<Descriptor>()
    private let archiver: KeyedArchiver
    private weak var delegate: DescriptorManagerDelegate?
    private let synchronizationQueue = dispatch_queue_create(DescriptorManager.QueueName, DISPATCH_QUEUE_SERIAL)

    // MARK:
    
    var backgroundEventsCompletionHandler: VoidBlock?

    // MARK:
    // MARK: Initialization
    
    convenience init(sessionManager: AFURLSessionManager, name: String)
    {
        self.init(sessionManager: sessionManager, name: name, delegate: nil)
    }
    
    // By passing the delegate into the constructor (as opposed to using a public property) 
    // We ensure that early events like "load" can be reported [AH] 11/25/2015
    
    init(sessionManager: AFURLSessionManager, name: String, delegate: DescriptorManagerDelegate?)
    {
        self.sessionManager = sessionManager
        self.name = name
        self.delegate = delegate
        self.archiver = DescriptorManager.setupArchiver(name: name)

        // We must load the descriptors before we set the sessionBlocks,
        // Otherwise the blocks will be called before we have a list of descriptors to reconcile with [AH] 10/28/ 2015
        
        self.loadDescriptors()

        self.delegate?.didLoadDescriptors(count: self.descriptors.count)

        self.setupSessionBlocks()
    }

    // MARK: Setup
    
    private static func setupArchiver(name name: String) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        var documentsURL = NSURL(string: documentsPath)!
        
        documentsURL = documentsURL.URLByAppendingPathComponent(name)
        documentsURL = documentsURL.URLByAppendingPathComponent(DescriptorManager.DescriptorsArchiveKey)
        
        if NSFileManager.defaultManager().fileExistsAtPath(documentsURL.path!) == false
        {
            try! NSFileManager.defaultManager().createDirectoryAtPath(documentsURL.path!, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path!)
    }
    
    private func loadDescriptors()
    {
        if let descriptors = self.archiver.loadObjectForKey(DescriptorManager.DescriptorsArchiveKey) as? Set<Descriptor>
        {
            for descriptor in descriptors
            {
                do
                {
                    try descriptor.didLoadFromCache(sessionManager: self.sessionManager)
                }
                catch let error as NSError
                {
                    self.delegate?.didFailToLoadDescriptor(error: error)
                    // TODO: remove this descriptor? Nil out background session completion handler block?
                }
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
                strongSelf.save()

                strongSelf.delegate?.sessionDidBecomeInvalid(error: error)
                
                NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.SessionDidBecomeInvalid.rawValue, object: error)
            })
        }
        
        self.sessionManager.setDownloadTaskDidFinishDownloadingBlock { [weak self] (session, task, url) -> NSURL? in

            guard let strongSelf = self else
            {
                return nil
            }

            var destination: NSURL? = nil

            dispatch_sync(strongSelf.synchronizationQueue, { [weak self] () -> Void in

                let strongSelf = self!

                guard let descriptor = strongSelf.descriptorForTask(task) else
                {
                    return
                }

                strongSelf.delegate?.downloadTaskDidFinishDownloading(task: task, descriptor: descriptor)

                if let url = descriptor.taskDidFinishDownloading(sessionManager: strongSelf.sessionManager, task: task, url: url)
                {
                    destination = url
                }
                
                strongSelf.save()
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

                strongSelf.delegate?.taskDidComplete(task: task, descriptor: descriptor, error: error)

                descriptor.taskDidComplete(sessionManager: strongSelf.sessionManager, task: task, error: error)

                strongSelf.save()
                
                if descriptor.state == State.Finished
                {
                    strongSelf.descriptors.remove(descriptor)
                    strongSelf.save()
                    
                    if descriptor.error != nil
                    {
                        strongSelf.delegate?.descriptorDidFail(descriptor)
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidFail.rawValue, object: descriptor)
                    }
                    else
                    {
                        strongSelf.delegate?.descriptorDidSucceed(descriptor)

                        NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidSucceed.rawValue, object: descriptor)
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
    
    func handleEventsForBackgroundURLSession(identifier identifier: String, completionHandler: VoidBlock) -> Bool
    {
        guard identifier == self.sessionManager.session.configuration.identifier else
        {
            return false
        }
        
        self.delegate?.willHandleEventsForBackgroundSession()

        self.backgroundEventsCompletionHandler = completionHandler
        
        return true
    }
    
    func addDescriptor(descriptor: Descriptor) // TODO: throw error?
    {
        // TODO: should this be async?
        
        dispatch_sync(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.descriptors.insert(descriptor)
            strongSelf.save()

            strongSelf.delegate?.descriptorWillStart(descriptor)

            NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorWillStart.rawValue, object: descriptor)
            
            do
            {
                try descriptor.start(sessionManager: strongSelf.sessionManager)
                strongSelf.save()
            }
            catch
            {
                strongSelf.descriptors.remove(descriptor)
                strongSelf.save()
                
                strongSelf.delegate?.descriptorDidFail(descriptor)
                
                NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidFail.rawValue, object: descriptor)
            }
        })
    }
    
    func descriptorPassingTest(test: TestBlock) -> Descriptor?
    {
        var descriptor: Descriptor?
        
        dispatch_sync(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            for currentDescriptor in strongSelf.descriptors
            {
                let didPass = test(descriptor: currentDescriptor)
                if didPass == true
                {
                    descriptor = currentDescriptor
                    break
                }
            }
        })
        
        return descriptor
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
        
        // If the descriptor is not found then the session.tasks and self.descriptors are out of sync (his is a major problem)
        // Or we're using the background session for a standalone task, independent of a descriptor
        
        if result == nil
        {
            self.delegate?.descriptorForTaskNotFound(task)
        }
        
        return result
    }
    
    private func save()
    {
        self.archiver.saveObject(self.descriptors, key: DescriptorManager.DescriptorsArchiveKey)
        self.delegate?.didSaveDescriptors(count: self.descriptors.count)
    }
}
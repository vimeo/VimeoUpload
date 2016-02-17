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
    case DescriptorAdded = "DescriptorAddedNotification"
    case DescriptorDidFail = "DescriptorDidFailNotification"
    case DescriptorDidSucceed = "DescriptorDidSucceedNotification"
    case SessionDidBecomeInvalid = "SessionDidBecomeInvalidNotification"
}

typealias TestBlock = (descriptor: Descriptor) -> Bool
typealias VoidBlock = () -> Void

class DescriptorManager
{
    private static let QueueName = "descriptor_manager.synchronization_queue"
    
    // MARK:
    
    private var sessionManager: AFURLSessionManager
    private let name: String
    private weak var delegate: DescriptorManagerDelegate?
    
    // MARK:
    
    private let archiver: DescriptorManagerArchiver // This object handles persistence of descriptors and suspended state to disk
    private let synchronizationQueue = dispatch_queue_create(DescriptorManager.QueueName, DISPATCH_QUEUE_SERIAL)

    // MARK:
    
    var suspended: Bool
    {
        get
        {
            return self.archiver.suspended
        }
    }
    
    // MARK:
    
    var backgroundEventsCompletionHandler: VoidBlock?

    // MARK: - Initialization
    
    // By passing the delegate into the constructor (as opposed to using a public property)
    // We ensure that early events like "load" can be reported [AH] 11/25/2015
    
    init(sessionManager: AFURLSessionManager, name: String, delegate: DescriptorManagerDelegate? = nil)
    {
        self.sessionManager = sessionManager
        self.name = name
        self.delegate = delegate
        self.archiver = DescriptorManagerArchiver(name: name)
        
        self.setupDescriptors()
        self.setupSessionBlocks()
        self.setupSuspendedState()
    }

    // MARK: Setup - State
    
    private func setupDescriptors()
    {
        var failedDescriptors: [Descriptor] = []
        for descriptor in self.archiver.descriptors
        {
            do
            {
                try descriptor.didLoadFromCache(sessionManager: self.sessionManager)
            }
            catch let error as NSError
            {
                descriptor.error = error
                failedDescriptors.append(descriptor)
            }
        }
        
        for descriptor in failedDescriptors
        {
            self.archiver.remove(descriptor)
            
            self.delegate?.descriptorDidFail?(descriptor)
            NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidFail.rawValue, object: descriptor)
        }
        
        self.archiver.save()
        self.delegate?.didLoadDescriptors?(count: self.archiver.descriptors.count)
    }
    
    private func setupSuspendedState()
    {
        if self.archiver.suspended == true
        {
            self.doSuspend() // Call doSuspend() because suspend() checks the property value
        }
    }
    
    // MARK: Setup - Session

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

                strongSelf.archiver.removeAll()

                strongSelf.delegate?.sessionDidBecomeInvalid?(error: error)
                
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

                guard let strongSelf = self,
                    let descriptor = strongSelf.descriptorForTask(task) else
                {
                    return
                }

                strongSelf.delegate?.downloadTaskDidFinishDownloading?(task: task, descriptor: descriptor)

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

                guard let strongSelf = self,
                    let descriptor = strongSelf.descriptorForTask(task) else
                {
                    return
                }

                strongSelf.delegate?.taskDidComplete?(task: task, descriptor: descriptor, error: error)
                descriptor.taskDidComplete(sessionManager: strongSelf.sessionManager, task: task, error: error)

                strongSelf.save()

                // If the descriptor is suspended, it means we've cancelled the task so we can start over from byte 0
                let isNetworkTaskCancellationError = error?.isNetworkTaskCancellationError() ?? false
                if descriptor.state == .Suspended && descriptor.isSuspendInitiatedCancellation && isNetworkTaskCancellationError
                {
                    return
                }
                
                if descriptor.state == .Finished
                {
                    strongSelf.archiver.remove(descriptor)
                    
                    if descriptor.error != nil
                    {
                        strongSelf.delegate?.descriptorDidFail?(descriptor)
                        NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidFail.rawValue, object: descriptor)
                    }
                    else
                    {
                        strongSelf.delegate?.descriptorDidSucceed?(descriptor)
                        NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidSucceed.rawValue, object: descriptor)
                    }
                }
            })
        }
        
        self.sessionManager.setDidFinishEventsForBackgroundURLSessionBlock { [weak self] (session) -> Void in

            if let strongSelf = self,
                let backgroundEventsCompletionHandler = strongSelf.backgroundEventsCompletionHandler
            {
                strongSelf.delegate?.didFinishEventsForBackgroundSession?()
                
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
        
        self.delegate?.willHandleEventsForBackgroundSession?()

        self.backgroundEventsCompletionHandler = completionHandler
        
        return true
    }
    
    func suspend()
    {
        if self.archiver.suspended == true
        {
            return
        }

        self.doSuspend()
    }
    
    func resume()
    {
        if self.archiver.suspended == false
        {
            return
        }
        
        self.doResume()
    }
    
    func addDescriptor(descriptor: Descriptor)
    {
        // TODO: should this be sync? Changed this to async due to deadlock related to notifications
        // Leaving as-is until we see reason to change
        
        dispatch_async(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.archiver.insert(descriptor)
            strongSelf.delegate?.descriptorAdded?(descriptor)
            NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorAdded.rawValue, object: descriptor)

            do
            {
                try descriptor.prepare(sessionManager: strongSelf.sessionManager)
                strongSelf.archiver.save()
                strongSelf.delegate?.didSaveDescriptors?(count: strongSelf.archiver.descriptors.count)
            }
            catch
            {
                strongSelf.archiver.remove(descriptor)
                strongSelf.delegate?.descriptorDidFail?(descriptor)
                NSNotificationCenter.defaultCenter().postNotificationName(DescriptorManagerNotification.DescriptorDidFail.rawValue, object: descriptor)
                
                return
            }

            if strongSelf.archiver.suspended
            {
                descriptor.state = .Suspended // TODO: figure out how to not set this externally like this
            }
            else
            {
                descriptor.resume(sessionManager: strongSelf.sessionManager)
            }

            strongSelf.save()
        })
    }
    
    func cancelDescriptor(descriptor: Descriptor)
    {
        descriptor.cancel(sessionManager: self.sessionManager)
    }
    
    func killAllDescriptors(completion completion: VoidClosure)
    {
        dispatch_async(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            // Get a reference to the descriptor list
            let descriptors = strongSelf.archiver.descriptors

            // Clear the list so that any completion calls have no impact on the system or observers (via early return / guard statements above)
            strongSelf.archiver.removeAll()
            strongSelf.save()

            // Cancel each descriptor to kill any in-flight network requests
            for descriptor in descriptors
            {
                descriptor.cancel(sessionManager: strongSelf.sessionManager)
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion()
            })
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

            descriptor = strongSelf.archiver.descriptorPassingTest(test)
        })
        
        return descriptor
    }
    
    // MARK: Private API
    
    private func doSuspend()
    {
        self.archiver.suspended = true
        
        dispatch_sync(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            for descriptor in strongSelf.archiver.descriptors
            {
                descriptor.suspend(sessionManager: strongSelf.sessionManager)
            }
            
            // Doing this after the loop rather than within, incrementally greater margin for error but faster
            strongSelf.save()
        })
    }
    
    private func doResume()
    {
        self.archiver.suspended = false
        
        dispatch_sync(self.synchronizationQueue, { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            for descriptor in strongSelf.archiver.descriptors
            {
                descriptor.resume(sessionManager: strongSelf.sessionManager)
            }
            
            // Doing this after the loop rather than within, incrementally greater margin for error but faster
            strongSelf.save()
        })
    }
    
    private func save()
    {
        self.archiver.save()
        self.delegate?.didSaveDescriptors?(count: self.archiver.descriptors.count)
    }

    private func descriptorForTask(task: NSURLSessionTask) -> Descriptor?
    {
        let descriptor = self.archiver.descriptorPassingTest { (descriptor) -> Bool in
            return descriptor.currentTaskIdentifier == task.taskIdentifier
        }
        
        // If the descriptor is not found then the session.tasks and self.descriptors are out of sync (his is a major problem)
        // Or we're using the background session for a standalone task, independent of a descriptor
        
        if descriptor == nil
        {
            self.delegate?.descriptorForTaskNotFound?(task)
        }
        
        return descriptor
    }    
}
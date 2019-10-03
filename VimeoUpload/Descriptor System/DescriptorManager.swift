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
import VimeoNetworking

public enum DescriptorManagerNotification: String
{
    case DescriptorAdded = "DescriptorAddedNotification"
    case DescriptorDidFail = "DescriptorDidFailNotification"
    case DescriptorDidSucceed = "DescriptorDidSucceedNotification"
    case DescriptorDidCancel = "DescriptorDidCancelNotification"
    case SessionDidBecomeInvalid = "SessionDidBecomeInvalidNotification"
}

public typealias TestClosure = (Descriptor) -> Bool
public typealias VoidClosure = () -> Void

@objc open class DescriptorManager: NSObject
{
    private struct Constants
    {
        static let QueueName = "descriptor_manager.synchronization_queue"
        static let ShareExtensionArchivePrefix = "share_extension"
        static let ShareExtensionDescriptorDidSuspend = "ShareExtensionDescriptorDidSuspend"
        
        struct InvalidationError
        {
            static let Domain = "BackgroundSessionInvalidationError"
            static let Code = 1
            static let LocalizedDescription = "A session object referring to the same background session has been invalidated and thus disconnected from the session."
        }
    }
    
    // MARK:
    
    private var sessionManager: VimeoSessionManager
    private let name: String
    private let archivePrefix: String?
    private weak var delegate: DescriptorManagerDelegate?
    
    // MARK:
    
    private let archiver: DescriptorManagerArchiver // This object handles persistence of descriptors and suspended state to disk
    private let synchronizationQueue = DispatchQueue(label: Constants.QueueName, attributes: [])

    // MARK:
    
    @objc open var suspended: Bool
    {
        return self.archiver.suspended
    }
    
    // MARK:
    
    @objc open var backgroundEventsCompletionHandler: VoidClosure?

    // MARK: - Initialization
    
    // By passing the delegate into the constructor (as opposed to using a public property)
    // We ensure that early events like "load" can be reported [AH] 11/25/2015
    
    @objc init?(sessionManager: VimeoSessionManager,
          name: String,
          archivePrefix: String?,
          documentsFolderURL: URL,
          delegate: DescriptorManagerDelegate? = nil)
    {
        guard let archiver = DescriptorManagerArchiver(name: name,
                                                       archivePrefix: archivePrefix,
                                                       documentsFolderURL: documentsFolderURL)
        else
        {
            return nil
        }
        
        self.sessionManager = sessionManager
        self.name = name
        self.delegate = delegate
        
        self.archiver = archiver
        self.archivePrefix = archivePrefix
        
        super.init()

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
            catch
            {
                failedDescriptors.append(descriptor)
            }
        }
        
        for descriptor in failedDescriptors
        {
            self.archiver.remove(descriptor: descriptor)
            
            self.delegate?.descriptorDidFail?(descriptor)
            NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: descriptor)
        }
        
        self.archiver.save()
        self.delegate?.didLoadDescriptors?(descriptors: self.archiver.descriptors)
    }
    
    private func setupSuspendedState()
    {
        if self.archiver.suspended == true
        {
            self.doSuspend() // Call doSuspend() because suspend() checks the property value
        }
    }
    
    // MARK: Setup - Session

    private func retry(_ descriptor: Descriptor) {
        do
        {
            try descriptor.retry(sessionManager: self.sessionManager)
            self.delegate?.descriptorDidResume?(descriptor)
            self.save()
        }
        catch
        {
            self.archiver.remove(descriptor: descriptor)
            
            self.delegate?.descriptorDidFail?(descriptor)
            NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: descriptor)
        }
    }
    
    private func setupSessionBlocks()
    {
        // To restate Alfie's comment on this session invalid callback, in the
        // past we did not want to invalidate a background session because we
        // wanted to handle upload events coming back to the app as soon as the
        // associated upload task is finished, so any invalidation might likely
        // be caused by a weird error that we could not handle. That assumption
        // is not true anymore unfortunately with the share extension. When the
        // app has to handle upload events coming from the share extension, it
        // must create an instance of `VimeoSessionManager` whose background ID
        // is the same as the one that made the upload task. Because
        // `VimeoSessionManager` retains `URLSession` while acting as its
        // delegate, and `URLSession` retains its delegate object until it is
        // invalidated, an explicit call to the `invalidate` method is necessary
        // to avoid leaking memory. If the underlying session is not invalidated,
        // not only the app will leak memory but the share extension won't be
        // able to upload due to the main app still binding to that session ID.
        // [VN] (07/03/2018)
        self.sessionManager.httpSessionManager.setSessionDidBecomeInvalidBlock { [weak self] (session, error) -> Void in

            guard let strongSelf = self else
            {
                return
            }

            strongSelf.synchronizationQueue.async(execute: { [weak self] () -> Void in

                guard let strongSelf = self else
                {
                    return
                }
                
                strongSelf.archiver.removeAll()
                
                // TODO: Need to respond to this notification [AH] 2/22/2016 (remove from downloads store, delete active uploads etc.)

                // Why do we need to check if `error` is `nil` even though the compiler
                // tells us that this checking will always succeed? Behind the scene, we
                // are using the `AFURLSessionManager` class -- which is an Objective-C
                // class -- for managing background upload sessions. For the session
                // invalid callback, its header file does not mark the `NSError` object
                // as nullable; in reality, this object will be `nil` if we explicitly
                // invalidate the underlying session. Because of that, it is necessary
                // to check for `nil` here, else the runtime will crash if the error
                // object is `nil`.
                //
                // In short, trying to safely unwrap `error` will result in a crash, so
                // as weird as it sounds, please do not do that here. [VN] (06/13/2018)
                
                // TODO: Either update AFNetworking to the latest version, or redesign
                // our networking library so that we have a better control over this
                // error. [VN] (07/03/2018)
                let theError: NSError?
                if error != nil
                {
                    let userInfo = [NSLocalizedDescriptionKey: Constants.InvalidationError.LocalizedDescription]
                    theError = NSError(domain: Constants.InvalidationError.Domain, code: Constants.InvalidationError.Code, userInfo: userInfo)
                }
                else
                {
                    theError = nil
                }
                
                strongSelf.delegate?.sessionDidBecomeInvalid?(error: theError)

                NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.SessionDidBecomeInvalid.rawValue), object: theError)
            })
        }
        
        self.sessionManager.httpSessionManager.setDownloadTaskDidFinishDownloadingBlock { [weak self] (session, task, url) -> URL? in

            guard let strongSelf = self else
            {
                return nil
            }

            var destination: URL? = nil

            strongSelf.synchronizationQueue.sync(execute: { [weak self] () -> Void in

                guard let strongSelf = self,
                    let descriptor = strongSelf.descriptor(for: task) else
                {
                    return
                }
                
                if descriptor.isCancelled
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
        
        self.sessionManager.httpSessionManager.setTaskDidComplete { [weak self] (session, task, error) -> Void in

            guard let strongSelf = self else
            {
                return
            }

            strongSelf.synchronizationQueue.async(execute: { [weak self] () -> Void in

                guard let strongSelf = self,
                    let descriptor = strongSelf.descriptor(for: task) else
                {
                    return
                }

                if descriptor.isCancelled
                {
                    return
                }

                if descriptor.state == .suspended
                {
                    do
                    {
                        try descriptor.prepare(sessionManager: strongSelf.sessionManager)
                    
                        strongSelf.save()
                    }
                    catch
                    {
                        strongSelf.archiver.remove(descriptor: descriptor)
                        
                        strongSelf.delegate?.descriptorDidFail?(descriptor)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: descriptor)
                    }

                    return
                }
                
                // For background upload tasks, keep in mind that if the device cannot
                // connect to the Internet, they will not give up right away. Instead,
                // they will be retried by the OS on our behalf. This timeout period is
                // determined by `URLSessionConfiguration`'s `timeoutIntervalForResource`
                // property. By default, it has a value of 7 days, meaning the OS will
                // attempt to retry for a week before returning with a connection error.
                // [VN] (07/03/2018)
                let isConnectionError = ((task.error as NSError?)?.isConnectionError() == true || (error as NSError?)?.isConnectionError() == true)
                
                guard isConnectionError == false else
                {
                    if let prefix = strongSelf.archivePrefix, prefix == Constants.ShareExtensionArchivePrefix
                    {
                        descriptor.suspend(sessionManager: strongSelf.sessionManager)
                        strongSelf.save()
                        
                        NotificationCenter.default.post(name: Notification.Name(Constants.ShareExtensionDescriptorDidSuspend), object: descriptor)
                    }
                    else
                    {
                        strongSelf.retry(descriptor)
                    }
                    
                    return
                }
                
                guard descriptor.shouldRetry(urlResponse: task.response) == false else
                {
                    strongSelf.retry(descriptor)
                    
                    return
                }
                
                strongSelf.delegate?.taskDidComplete?(task: task, descriptor: descriptor, error: error as NSError?)
                descriptor.taskDidComplete(sessionManager: strongSelf.sessionManager, task: task, error: error as NSError?)
                
                if descriptor.state == .finished
                {
                    if let error = descriptor.error
                    {
                        // When a user initiates a descriptor and then kills the app from multitasking we will receive a networkTaskCancellation error
                        // In this case we don't want to disappear the descriptor, instead we want to flag it as an error
                        // However, the code below that would track/persist that type of failure does not always execute when the app is killed
                        // So we're intentionally not removing the descriptor from the list, 
                        // So that the error is tracked/persisted on next launch via loadFromCache above [AH] 3/15/2016
                        
                        if error.isNetworkTaskCancellationError() == false
                        {
                            strongSelf.archiver.remove(descriptor: descriptor)
                        }
                        
                        strongSelf.delegate?.descriptorDidFail?(descriptor)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: descriptor)
                    }
                    else
                    {
                        strongSelf.archiver.remove(descriptor: descriptor)

                        strongSelf.delegate?.descriptorDidSucceed?(descriptor)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidSucceed.rawValue), object: descriptor)
                    }
                }
            })
        }
        
        self.sessionManager.httpSessionManager.setDidFinishEventsForBackgroundURLSessionBlock { [weak self] (session) -> Void in

            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.synchronizationQueue.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
 
                if let backgroundEventsCompletionHandler = strongSelf.backgroundEventsCompletionHandler
                {
                    // The completionHandler must be called on the main thread
                    DispatchQueue.main.async(execute: { [weak self] () -> Void in
                        
                        guard let strongSelf = self else
                        {
                            return
                        }

                        strongSelf.delegate?.didFinishEventsForBackgroundSession?()
                        backgroundEventsCompletionHandler()
                        strongSelf.backgroundEventsCompletionHandler = nil
                    })
                }
            })
        }
    }
    
    // MARK: Public API
    
    /// Invalidate the underlying session manager object. You should
    /// call this method whenever you're finished using the descriptor
    /// manager, else you'll risk leaking memory.
    @objc public func invalidateSessionManager()
    {
        self.sessionManager.invalidate(cancelingPendingTasks: false)
    }
    
    /// Determines if the manager can handle events from a background upload
    /// session.
    ///
    /// Each descriptor manager is backed with a background upload session.
    /// If the upload is in progress, and your app enters background mode,
    /// this upload session still continues its progress. Once the upload
    /// task either completes or fails, it will ping your app delegate so
    /// that your app has an opportunity to handle the session's events.
    /// Use or override this method to check if the descriptor manager
    /// should handle events from the background session.
    ///
    /// - Parameter identifier: The identifier of a background session.
    /// - Returns: `true` if the identifier is the same as the underlying
    /// background upload session and thus the descriptor manager should
    /// handle the events. `false` otherwise.
    @objc open func canHandleEventsForBackgroundURLSession(withIdentifier identifier: String) -> Bool
    {
        return identifier == self.sessionManager.httpSessionManager.session.configuration.identifier
    }
    
    @objc open func handleEventsForBackgroundURLSession(completionHandler: @escaping VoidClosure)
    {
        self.delegate?.willHandleEventsForBackgroundSession?()

        self.backgroundEventsCompletionHandler = completionHandler
    }
    
    @objc open func suspend()
    {
        if self.archiver.suspended == true
        {
            return
        }

        self.doSuspend()
    }
    
    @objc open func resume()
    {
        if self.archiver.suspended == false
        {
            return
        }
        
        self.doResume()
    }
    
    @objc open func add(descriptor: Descriptor)
    {
        self.synchronizationQueue.async(execute: { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.archiver.insert(descriptor: descriptor)
            strongSelf.delegate?.descriptorAdded?(descriptor)
            NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorAdded.rawValue), object: descriptor)

            do
            {
                try descriptor.prepare(sessionManager: strongSelf.sessionManager)
                strongSelf.archiver.save()
                strongSelf.delegate?.didSaveDescriptors?(count: strongSelf.archiver.descriptors.count)
            }
            catch
            {
                strongSelf.archiver.remove(descriptor: descriptor)
                strongSelf.delegate?.descriptorDidFail?(descriptor)
                NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: descriptor)
                
                return
            }

            if strongSelf.archiver.suspended
            {
                descriptor.suspend(sessionManager: strongSelf.sessionManager)
            }
            else
            {
                descriptor.resume(sessionManager: strongSelf.sessionManager)
            }

            strongSelf.save()
        })
    }
    
    @objc open func cancel(descriptor: Descriptor)
    {
        self.synchronizationQueue.async(execute: { [weak self] () -> Void in

            guard let strongSelf = self else
            {
                return
            }

            strongSelf.archiver.remove(descriptor: descriptor)

            descriptor.cancel(sessionManager: strongSelf.sessionManager)
            
            strongSelf.delegate?.descriptorDidCancel?(descriptor)
            NotificationCenter.default.post(name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: descriptor)

        })
    }
    
    @objc open func killAllDescriptors(completion: @escaping VoidClosure)
    {
        self.synchronizationQueue.async(execute: { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            // Get a reference to the descriptor list
            let descriptors = strongSelf.archiver.descriptors

            // Clear the list so that any completion calls have no impact on the system or observers (via early return / guard statements above)
            
            // TODO: Post notifications from here [AH] 2/22/2016 (respond in download store and my videos?)
            
            strongSelf.archiver.removeAll()
            strongSelf.save()

            // Cancel each descriptor to kill any in-flight network requests
            for descriptor in descriptors
            {
                descriptor.cancel(sessionManager: strongSelf.sessionManager)
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                completion()
            })
        })
    }
    
    @objc open func descriptor(passing test: @escaping TestClosure) -> Descriptor?
    {
        var descriptor: Descriptor?
        
        self.synchronizationQueue.sync(execute: { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            descriptor = strongSelf.archiver.descriptor(passing: test)
        })
        
        return descriptor
    }
    
    // MARK: Private API
    
    private func doSuspend()
    {
        self.archiver.suspended = true
        
        self.synchronizationQueue.async(execute: { [weak self] () -> Void in
            
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
        
        self.synchronizationQueue.async(execute: { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            for descriptor in strongSelf.archiver.descriptors
            {
                descriptor.resume(sessionManager: strongSelf.sessionManager)
                
                strongSelf.delegate?.descriptorDidResume?(descriptor)
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

    private func descriptor(for task: URLSessionTask) -> Descriptor?
    {
        let descriptor = self.archiver.descriptor(passing: { (descriptor) -> Bool in
            return descriptor.currentTaskIdentifier == task.taskIdentifier
        })
        
        // If the descriptor is not found then the session.tasks and self.descriptors are out of sync (his is a major problem)
        // Or we're using the background session for a standalone task, independent of a descriptor
        
        if descriptor == nil
        {
            self.delegate?.descriptorForTaskNotFound?(task)
        }
        
        return descriptor
    }    
}

//
//  RetryManager.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/23/15.
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
import AFNetworking
import VimeoNetworking

public class VideoDeletionManager: NSObject
{
    private static let DeletionsArchiveKey = "deletions"
    private static let DefaultRetryCount = 3
    
    // MARK:
    
    private let sessionManager: VimeoSessionManager
    private let retryCount: Int
    
    // MARK:
    
    private var deletions: [VideoUri: Int] = [:]
    private let operationQueue: NSOperationQueue
    private let archiver: KeyedArchiver
    
    // MARK: - Initialization
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
        self.removeObservers()
    }
        
    init(sessionManager: VimeoSessionManager, retryCount: Int = VideoDeletionManager.DefaultRetryCount)
    {
        self.sessionManager = sessionManager
        self.retryCount = retryCount
     
        self.operationQueue = NSOperationQueue()
        self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
        self.archiver = VideoDeletionManager.setupArchiver(name: VideoDeletionManager.DeletionsArchiveKey)
        
        super.init()
        
        self.addObservers()
        self.reachabilityDidChange(nil) // Set suspended state
        
        self.deletions = self.loadDeletions()
        self.startDeletions()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(name name: String) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        var documentsURL = NSURL(string: documentsPath)!
        
        documentsURL = documentsURL.URLByAppendingPathComponent(name)
        documentsURL = documentsURL.URLByAppendingPathComponent(VideoDeletionManager.DeletionsArchiveKey)
        
        if NSFileManager.defaultManager().fileExistsAtPath(documentsURL.path!) == false
        {
            try! NSFileManager.defaultManager().createDirectoryAtPath(documentsURL.path!, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path!)
    }
    
    // MARK: Archiving
    
    private func loadDeletions() -> [VideoUri: Int]
    {
        if let deletions = self.archiver.loadObjectForKey(self.dynamicType.DeletionsArchiveKey) as? [VideoUri: Int]
        {
            return deletions
        }
        
        return [:]
    }

    private func startDeletions()
    {
        for (key, value) in self.deletions
        {
            self.deleteVideoWithUri(key, retryCount: value)
        }
    }
    
    private func save()
    {
        self.archiver.saveObject(self.deletions, key: self.dynamicType.DeletionsArchiveKey)
    }
    
    // MARK: Public API
    
    func deleteVideoWithUri(uri: String)
    {
        self.deleteVideoWithUri(uri, retryCount: self.retryCount)
    }
    
    // MARK: Private API

    private func deleteVideoWithUri(uri: String, retryCount: Int)
    {
        self.deletions[uri] = retryCount
        self.save()
        
        let operation = DeleteVideoOperation(sessionManager: self.sessionManager, videoUri: uri)
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.cancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    if let response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse where response.statusCode == 404
                    {
                        strongSelf.deletions.removeValueForKey(uri) // The video has already been deleted
                        strongSelf.save()

                        return
                    }
                    
                    if let retryCount = strongSelf.deletions[uri] where retryCount > 0
                    {
                        let newRetryCount = retryCount - 1
                        strongSelf.deleteVideoWithUri(uri, retryCount: newRetryCount) // Decrement the retryCount and try again
                    }
                    else
                    {
                        strongSelf.deletions.removeValueForKey(uri) // We retried the required number of times, nothing more to do
                        strongSelf.save()
                    }
                }
                else
                {
                    strongSelf.deletions.removeValueForKey(uri)
                    strongSelf.save()
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoDeletionManager.reachabilityDidChange(_:)), name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    func applicationWillEnterForeground(notification: NSNotification)
    {
        self.operationQueue.suspended = false
    }

    func applicationDidEnterBackground(notification: NSNotification)
    {
        self.operationQueue.suspended = true
    }

    func reachabilityDidChange(notification: NSNotification?)
    {
        let currentlyReachable = AFNetworkReachabilityManager.sharedManager().reachable
        
        self.operationQueue.suspended = !currentlyReachable
    }
}
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

class VideoDeletionManager: NSObject
{
    private static let DeletionsArchiveKey = "deletions"
    
    // MARK:
    
    private let sessionManager: VimeoSessionManager
    private let retryCount: Int
    
    // MARK:
    
    private var deletions: [String: Int] = [:]
    private let operationQueue: NSOperationQueue
    private let archiver: KeyedArchiver

    // MARK:
    // MARK: Initialization
    
    deinit
    {
        self.removeObservers()
    }
    
    // TODO: support deletion of password protected videos
    
    init(sessionManager: VimeoSessionManager, retryCount: Int)
    {
        self.sessionManager = sessionManager
        self.retryCount = retryCount
     
        self.operationQueue = NSOperationQueue()
        self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
        self.archiver = VideoDeletionManager.setupArchiver(name: VideoDeletionManager.DeletionsArchiveKey)
   
        super.init()
        
        self.addObservers()
        
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
    
    private func loadDeletions() -> [String: Int]
    {
        if let deletions = self.archiver.loadObjectForKey(VideoDeletionManager.DeletionsArchiveKey) as? [String: Int]
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
        self.archiver.saveObject(self.deletions, key: VideoDeletionManager.DeletionsArchiveKey)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func applicationDidBecomeActive(notification: NSNotification)
    {
        self.startDeletions()
    }

    func applicationWillResignActive(notification: NSNotification)
    {
        self.operationQueue.cancelAllOperations()
    }
}
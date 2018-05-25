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
    private let operationQueue: OperationQueue
    private let archiver: KeyedArchiver
    private let shouldLoadArchive: Bool
    
    // MARK: - Initialization
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
        self.removeObservers()
    }
        
    public init(sessionManager: VimeoSessionManager, retryCount: Int = VideoDeletionManager.DefaultRetryCount, archivePrefix: String? = nil, shouldLoadArchive: Bool = true)
    {
        self.sessionManager = sessionManager
        self.retryCount = retryCount
        self.shouldLoadArchive = shouldLoadArchive
     
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        self.archiver = VideoDeletionManager.setupArchiver(name: VideoDeletionManager.DeletionsArchiveKey, archivePrefix: archivePrefix)
        
        super.init()
        
        self.addObservers()
        self.reachabilityDidChange(nil) // Set suspended state
        
        self.deletions = self.loadDeletions()
        self.startDeletions()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(name: String, archivePrefix: String?) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var documentsURL = URL(string: documentsPath)!
        
        documentsURL = documentsURL.appendingPathComponent(name)
        documentsURL = documentsURL.appendingPathComponent(VideoDeletionManager.DeletionsArchiveKey)
        
        if FileManager.default.fileExists(atPath: documentsURL.path) == false
        {
            try! FileManager.default.createDirectory(atPath: documentsURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path, archivePrefix: archivePrefix)
    }
    
    // MARK: Archiving
    
    private func loadDeletions() -> [VideoUri: Int]
    {
        guard self.shouldLoadArchive == true else
        {
            return [:]
        }
        
        if let deletions = self.archiver.loadObject(for: type(of: self).DeletionsArchiveKey) as? [VideoUri: Int]
        {
            return deletions
        }
        
        return [:]
    }

    private func startDeletions()
    {
        for (key, value) in self.deletions
        {
            self.deleteVideo(withURI: key, retryCount: value)
        }
    }
    
    private func save()
    {
        self.archiver.save(object: self.deletions, key: type(of: self).DeletionsArchiveKey)
    }
    
    // MARK: Public API
    
    public func deleteVideo(withURI uri: String)
    {
        self.deleteVideo(withURI: uri, retryCount: self.retryCount)
    }
    
    // MARK: Private API

    private func deleteVideo(withURI uri: String, retryCount: Int)
    {
        self.deletions[uri] = retryCount
        self.save()
        
        let operation = DeleteVideoOperation(sessionManager: self.sessionManager, videoUri: uri)
        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    if let response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse, response.statusCode == 404
                    {
                        strongSelf.deletions.removeValue(forKey: uri) // The video has already been deleted
                        strongSelf.save()

                        return
                    }
                    
                    if let retryCount = strongSelf.deletions[uri], retryCount > 0
                    {
                        let newRetryCount = retryCount - 1
                        strongSelf.deleteVideo(withURI: uri, retryCount: newRetryCount) // Decrement the retryCount and try again
                    }
                    else
                    {
                        strongSelf.deletions.removeValue(forKey: uri) // We retried the required number of times, nothing more to do
                        strongSelf.save()
                    }
                }
                else
                {
                    strongSelf.deletions.removeValue(forKey: uri)
                    strongSelf.save()
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoDeletionManager.reachabilityDidChange(_:)), name: Notification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    func applicationWillEnterForeground(_ notification: Notification)
    {
        self.operationQueue.isSuspended = false
    }

    func applicationDidEnterBackground(_ notification: Notification)
    {
        self.operationQueue.isSuspended = true
    }

    func reachabilityDidChange(_ notification: Notification?)
    {
        let currentlyReachable = AFNetworkReachabilityManager.shared().isReachable
        
        self.operationQueue.isSuspended = !currentlyReachable
    }
}

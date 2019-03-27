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

@objc public class VideoDeletionManager: NSObject
{
    @objc public static let DeletionDefaultRetryCount = 3
    private static let DeletionsArchiveKey = "deletions"
    
    // MARK:
    
    private let sessionManager: VimeoSessionManager
    private let retryCount: Int
    
    // MARK:
    
    private var deletions: [VideoUri: Int] = [:]
    private let operationQueue: OperationQueue
    private let archiver: KeyedArchiver
    
    // MARK: - Initialization
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
        self.removeObservers()
    }
    
    /// Initializes a video deletion manager object. Upon creation, the
    /// object will attempt to create a folder to save deletion information
    /// if needed. If the folder already exists, it will attempt to load
    /// that information into memory, then perform deletion.
    ///
    /// The folder is created with the following scheme:
    ///
    /// ```
    /// Documents/deletions
    /// ```
    ///
    /// - Parameters:
    ///   - sessionManager: A session manager object capable of deleting
    ///   uploads.
    ///   - archivePrefix: The prefix of the archive file. You pass in the
    ///   prefix if you want to keep track of multiple archive files. By
    ///   default, it has the value of `nil`.
    ///   - documentsFolderURL: The Documents folder's URL in which the folder
    /// is located.
    ///   - retryCount: The number of retries. The default value is `3`.
    /// - Returns: `nil` if the keyed archiver cannot load deletions' archive.
    @objc public init?(sessionManager: VimeoSessionManager,
                 archivePrefix: String? = nil,
                 documentsFolderURL: URL,
                 retryCount: Int = VideoDeletionManager.DeletionDefaultRetryCount)
    {
        guard let archiver = VideoDeletionManager.setupArchiver(name: VideoDeletionManager.DeletionsArchiveKey, archivePrefix: archivePrefix, documentsFolderURL: documentsFolderURL) else
        {
            return nil
        }
        
        self.archiver = archiver
        
        self.sessionManager = sessionManager
        self.retryCount = retryCount
     
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        
        super.init()
        
        self.addObservers()
        self.reachabilityDidChange(nil) // Set suspended state
        
        let migrator = ArchiveMigrator(fileManager: FileManager.default)
        self.deletions = self.loadDeletions(withMigrator: migrator)
        self.startDeletions()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(name: String, archivePrefix: String?, documentsFolderURL: URL) -> KeyedArchiver?
    {
        let deletionsFolder = documentsFolderURL.appendingPathComponent(name)
        let deletionsArchiveDirectory = deletionsFolder.appendingPathComponent(VideoDeletionManager.DeletionsArchiveKey)
        
        if FileManager.default.fileExists(atPath: deletionsArchiveDirectory.path) == false
        {
            do
            {
                try FileManager.default.createDirectory(at: deletionsArchiveDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                return nil
            }
        }
        
        return KeyedArchiver(basePath: deletionsArchiveDirectory.path, archivePrefix: archivePrefix)
    }
    
    // MARK: Archiving
    
    private func loadDeletions(withMigrator migrator: ArchiveMigrating?) -> [VideoUri: Int]
    {
        let relativeFolderURL = URL(string: VideoDeletionManager.DeletionsArchiveKey)?.appendingPathComponent(VideoDeletionManager.DeletionsArchiveKey)
        guard let retries = ArchiveDataLoader.loadData(relativeFolderURL: relativeFolderURL,
                                                       archiver: self.archiver,
                                                       key: VideoDeletionManager.DeletionsArchiveKey) as? [VideoUri: Int]
        else
        {
            return [:]
        }
        
        return retries
    }

    private func startDeletions()
    {
        for (key, value) in deletions
        {
            self.deleteVideo(withURI: key, retryCount: value)
        }
    }
    
    private func save()
    {
        self.archiver.save(object: deletions, key: type(of: self).DeletionsArchiveKey)
    }
    
    // MARK: Public API
    
    @objc public func deleteVideo(withURI uri: String)
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
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoDeletionManager.reachabilityDidChange(_:)), name: Notification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    @objc func applicationWillEnterForeground(_ notification: Notification)
    {
        self.operationQueue.isSuspended = false
    }

    @objc func applicationDidEnterBackground(_ notification: Notification)
    {
        self.operationQueue.isSuspended = true
    }

    @objc func reachabilityDidChange(_ notification: Notification?)
    {
        let currentlyReachable = AFNetworkReachabilityManager.shared().isReachable
        
        self.operationQueue.isSuspended = !currentlyReachable
    }
}

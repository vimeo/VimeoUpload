//
//  UploadManager.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/18/15.
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

@objc class UploadManager: NSObject
{
    static let sharedInstance = UploadManager()

    // MARK:
    
    private static let BackgroundSessionIdentifier = "com.vimeo.upload"
    private static let DescriptorManagerName = "uploader"
    private static let AuthToken = "caf4648129ec56e580175c4b45cce7fc"
    private static let FailedDescriptorsArchiveKey = "failed_descriptors"
    
    // MARK: 
    
    private let sessionManager: VimeoSessionManager
    private let descriptorManager: DescriptorManager
    private let deletionManager: VideoDeletionManager
    private let archiver: KeyedArchiver
    
    // MARK:

    private let reporter: UploadReporter = UploadReporter()
    private var failedDescriptors: [String: SimpleUploadDescriptor] = [:]
    
    // MARK:
    // MARK: Initialization
    
    deinit
    {
        self.removeObservers()
    }
    
    override init()
    {
        self.sessionManager = VimeoSessionManager.backgroundSessionManager(identifier: UploadManager.BackgroundSessionIdentifier, authToken: UploadManager.AuthToken)
        self.descriptorManager = DescriptorManager(sessionManager: self.sessionManager, name: UploadManager.DescriptorManagerName, delegate: self.reporter)
        self.deletionManager = VideoDeletionManager(sessionManager: ForegroundSessionManager.sharedInstance, retryCount: 2)
        self.archiver = UploadManager.setupArchiver(name: UploadManager.DescriptorManagerName)

        super.init()

        self.failedDescriptors = self.loadFailedDescriptors()
        print("Loaded \(self.failedDescriptors.count) failed descriptors")
        
        self.addObservers()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(name name: String) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        var documentsURL = NSURL(string: documentsPath)!
        
        documentsURL = documentsURL.URLByAppendingPathComponent(name)
        documentsURL = documentsURL.URLByAppendingPathComponent(UploadManager.FailedDescriptorsArchiveKey)
        
        if NSFileManager.defaultManager().fileExistsAtPath(documentsURL.path!) == false
        {
            try! NSFileManager.defaultManager().createDirectoryAtPath(documentsURL.path!, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path!)
    }
    
    private func loadFailedDescriptors() -> [String: SimpleUploadDescriptor]
    {
        if let failedDescriptors = self.archiver.loadObjectForKey(UploadManager.FailedDescriptorsArchiveKey) as? [String: SimpleUploadDescriptor]
        {
            return failedDescriptors
        }
        
        return [:]
    }
    
    private func save()
    {
        self.archiver.saveObject(self.failedDescriptors, key: UploadManager.FailedDescriptorsArchiveKey)
        print("Saved \(self.failedDescriptors.count) failed descriptors")
    }
    
    // MARK: Public API
    
    func applicationDidFinishLaunching()
    {
        // Do nothing at the moment
    }
    
    func handleEventsForBackgroundURLSession(identifier identifier: String, completionHandler: VoidBlock) -> Bool
    {
        return self.descriptorManager.handleEventsForBackgroundURLSession(identifier: identifier, completionHandler: completionHandler)
    }
    
    func uploadVideo(url url: NSURL, uploadTicket: VIMUploadTicket)
    {
        let descriptor = SimpleUploadDescriptor(url: url, uploadTicket: uploadTicket)
        descriptor.identifier = uploadTicket.video!.uri
        
        self.descriptorManager.addDescriptor(descriptor)
    }
    
    func deleteUpload(videoUri videoUri: String)
    {
        if let descriptor = self.uploadDescriptorForVideo(videoUri: videoUri)
        {
            descriptor.cancel(sessionManager: self.sessionManager)
        }
        
        if let _ = self.failedDescriptors.removeValueForKey(videoUri)
        {
            self.save()
        }
        
        self.deletionManager.deleteVideoWithUri(videoUri)
    }

    func uploadDescriptorForVideo(videoUri videoUri: String) -> SimpleUploadDescriptor?
    {
        // Check active descriptors
        var descriptor = self.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
            
            if let descriptor = descriptor as? SimpleUploadDescriptor, let currentVideoUri = descriptor.uploadTicket.video?.uri
            {
                return videoUri == currentVideoUri
            }
            
            return false
        })
        
        // Then check failed descriptors
        if descriptor == nil
        {
            descriptor = self.failedDescriptors[videoUri]
        }
        
        return descriptor as? SimpleUploadDescriptor
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "descriptorDidFail:", name: DescriptorManagerNotification.DescriptorDidFail.rawValue, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func descriptorDidFail(notification: NSNotification)
    {
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in

            guard let strongSelf = self else
            {
                return
            }
            
            if let descriptor = notification.object as? SimpleUploadDescriptor, let videoUri = descriptor.uploadTicket.video?.uri, let error = descriptor.error
            {
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled // No need to store failures that occurred due to cancellation
                {
                    return
                }
                
                strongSelf.failedDescriptors[videoUri] = descriptor
                strongSelf.save()
            }
        }
    }
}

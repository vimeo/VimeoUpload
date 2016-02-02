//
//  UploadFailureTracker.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/9/15.
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

@objc class UploadFailureTracker: NSObject
{
    private static let FailedDescriptorsArchiveKey = "failed_descriptors"

    // MARK: 
    
    private let archiver: KeyedArchiver
    private var failedDescriptors: [VideoUri: Upload2Descriptor] = [:]

    // MARK: - Initialization
    
    deinit
    {
        self.removeObservers()
    }
    
    init(name: String)
    {
        self.archiver = self.dynamicType.setupArchiver(name: name)

        super.init()
        
        self.failedDescriptors = self.loadFailedDescriptors()

        self.addObservers()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(name name: String) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        var documentsURL = NSURL(string: documentsPath)!
        documentsURL = documentsURL.URLByAppendingPathComponent(UploadFailureTracker.FailedDescriptorsArchiveKey)
        documentsURL = documentsURL.URLByAppendingPathComponent(name)
        
        if NSFileManager.defaultManager().fileExistsAtPath(documentsURL.path!) == false
        {
            try! NSFileManager.defaultManager().createDirectoryAtPath(documentsURL.path!, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path!)
    }
    
    private func loadFailedDescriptors() -> [VideoUri: Upload2Descriptor]
    {
        return self.archiver.loadObjectForKey(UploadFailureTracker.FailedDescriptorsArchiveKey) as? [VideoUri: Upload2Descriptor] ?? [:]
    }
    
    private func saveFailedDescriptors()
    {
        self.archiver.saveObject(self.failedDescriptors, key: UploadFailureTracker.FailedDescriptorsArchiveKey)
    }
    
    // MARK: Public API
    
    func removeFailedDescriptorForVideoUri(videoUri: VideoUri) -> Descriptor?
    {
        guard let descriptor = self.failedDescriptors.removeValueForKey(videoUri) else
        {
            return nil
        }
        
        self.saveFailedDescriptors()

        return descriptor
    }
    
    func failedDescriptorForVideoUri(videoUri: VideoUri) -> Descriptor?
    {
        return self.failedDescriptors[videoUri]
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "descriptorDidFail:", name: DescriptorManagerNotification.DescriptorDidFail.rawValue, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DescriptorManagerNotification.DescriptorDidFail.rawValue, object: nil)
    }
    
    func descriptorDidFail(notification: NSNotification)
    {
        // TODO: Should we do this:
        // Leaving this in place until we see reason to change it
        
        // Intentionally holding a strong reference to self here to ensure that this block executes,
        // Otherwise we potentially lose access to failures
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in // TODO: can async cause failure to not be stored?
            
            if let descriptor = notification.object as? Upload2Descriptor, let videoUri = descriptor.uploadTicket.video?.uri, let error = descriptor.error
            {
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled // No need to store failures that occurred due to cancellation
                {
                    return
                }
                
                self.failedDescriptors[videoUri] = descriptor
                self.saveFailedDescriptors()
            }
        }
    }
}
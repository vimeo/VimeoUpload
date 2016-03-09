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

class UploadManager
{
    static let sharedInstance = UploadManager()
    
    // MARK:
    
    private let failureTracker: VideoDescriptorFailureTracker
    private let deletionManager: VideoDeletionManager
    private let tracker = DescriptorManagerTracker()
    
    // MARK:
    
    let descriptorManager: ReachableDescriptorManager
    let foregroundSessionManager: VimeoSessionManager
    
    // MARK: - Initialization
    
    init()
    {
        let name = "uploader"
        let backgroundSessionIdentifier = "com.vimeo.upload"
        let authTokenBlock = { () -> String? in
            return "3e9dae312853936216aba3ce56cf5066"
        }
        
        self.foregroundSessionManager = VimeoSessionManager.defaultSessionManagerWithAuthTokenBlock(authTokenBlock: authTokenBlock)
        self.failureTracker = VideoDescriptorFailureTracker(name: name)
        self.deletionManager = VideoDeletionManager(sessionManager: self.foregroundSessionManager)
        self.descriptorManager = ReachableDescriptorManager(name: name, backgroundSessionIdentifier: backgroundSessionIdentifier, descriptorManagerDelegate: self.tracker, authTokenBlock: authTokenBlock)
    }

    // MARK: Public API
    
    // We need a reference (via the assetIdentifier) to the original asset so that we can retry failed uploads

    func uploadVideo(url url: NSURL, assetIdentifier: String, videoSettings: VideoSettings?)
    {
        let descriptor = Upload1Descriptor(url: url, assetIdentifier: assetIdentifier, videoSettings: videoSettings)
        descriptor.identifier = assetIdentifier
        
        self.descriptorManager.addDescriptor(descriptor)
    }
    
    func retryUpload(descriptor descriptor: Upload1Descriptor, url: NSURL)
    {
        if let videoUri = descriptor.uploadTicket?.video?.uri
        {
            self.failureTracker.removeFailedDescriptorForKey(videoUri)
        }
        
        let newDescriptor = Upload1Descriptor(url: url, assetIdentifier: descriptor.assetIdentifier, videoSettings: descriptor.videoSettings)
        newDescriptor.identifier = descriptor.assetIdentifier
        
        self.descriptorManager.addDescriptor(newDescriptor)
    }
    
    func deleteUpload(assetIdentifier assetIdentifier: String)
    {
        if let descriptor = self.uploadDescriptorForAssetIdentifier(assetIdentifier)
        {
            self.descriptorManager.cancelDescriptor(descriptor)
        
            if let videoUri = descriptor.videoUri
            {
                self.deletionManager.deleteVideoWithUri(videoUri) // Delete the video from the server if upload completed
            }
        }
    }
    
    func uploadDescriptorForAssetIdentifier(assetIdentifier: String) -> Upload1Descriptor?
    {
        // Check active descriptors
        let descriptor = self.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
            
            if let descriptor = descriptor as? Upload1Descriptor
            {
                return assetIdentifier == descriptor.assetIdentifier
            }
            
            return false
        })
        
        return descriptor as? Upload1Descriptor
    }    
}

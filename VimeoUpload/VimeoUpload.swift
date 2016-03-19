//
//  VimeoUpload.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 3/9/16.
//  Copyright © 2016 Vimeo. All rights reserved.
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

class VimeoUpload<T: VideoDescriptor>
{
    static var Name: String
    {
        return "vimeo_upload" // Generic types don't yet support static properties [AH] 3/19/2016
    }
    
    // MARK:
    
    let descriptorManager: ReachableDescriptorManager
    let foregroundSessionManager: VimeoSessionManager
    
    // MARK: 
    
    private let deletionManager: VideoDeletionManager

    // MARK: - Initialization

    convenience init(backgroundSessionIdentifier: String, authToken: String)
    {
        self.init(backgroundSessionIdentifier: backgroundSessionIdentifier, authTokenBlock: { () -> String? in
            return authToken
        })
    }

    init(backgroundSessionIdentifier: String, authTokenBlock: AuthTokenBlock)
    {
        self.foregroundSessionManager = VimeoSessionManager.defaultSessionManager(authTokenBlock: authTokenBlock)
        self.deletionManager = VideoDeletionManager(sessionManager: self.foregroundSessionManager)
        self.descriptorManager = ReachableDescriptorManager(name: self.dynamicType.Name, backgroundSessionIdentifier: backgroundSessionIdentifier, authTokenBlock: authTokenBlock)
    }
    
    // MARK: Public API - Starting

    func applicationDidFinishLaunching()
    {
        // No-op
    }
    
    func uploadVideo(descriptor descriptor: T)
    {
        self.descriptorManager.addDescriptor(descriptor.progressDescriptor)
    }

    // MARK: Public API - Canceling

    func cancelUpload(videoUri videoUri: VideoUri)
    {
        self.deletionManager.deleteVideoWithUri(videoUri)
        
        if let descriptor = self.descriptorForVideo(videoUri: videoUri)
        {
            self.descriptorManager.cancelDescriptor(descriptor.progressDescriptor)
        }
    }

    func cancelUpload(descriptor descriptor: VideoDescriptor)
    {
        if let videoUri = descriptor.videoUri
        {
            self.deletionManager.deleteVideoWithUri(videoUri)
        }
        
        self.descriptorManager.cancelDescriptor(descriptor.progressDescriptor)
    }

    func cancelUpload(identifier identifier: String)
    {
        if let descriptor = self.descriptorForIdentifier(identifier)
        {
            if let videoUri = descriptor.videoUri
            {
                self.deletionManager.deleteVideoWithUri(videoUri)
            }

            self.descriptorManager.cancelDescriptor(descriptor.progressDescriptor)
        }
    }
    
    // MARK: Public API - Accessing

    func descriptorForVideo(videoUri videoUri: VideoUri) -> T?
    {
        let descriptor = self.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
            
            if let descriptor = descriptor as? VideoDescriptor, let currentVideoUri = descriptor.videoUri
            {
                return videoUri == currentVideoUri
            }
            
            return false
        })
        
        return descriptor as? T
    }
    
    func descriptorForIdentifier(identifier: String) -> T?
    {
        let descriptor = self.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
            
            if let descriptor = descriptor as? VideoDescriptor, let currentIdentifier = descriptor.progressDescriptor.identifier
            {
                return identifier == currentIdentifier
            }
            
            return false
        })
        
        return descriptor as? T
    }
}
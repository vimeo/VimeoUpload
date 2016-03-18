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
    private let name = "vimeo_upload"
    
    // MARK:
    
    let descriptorManager: ReachableDescriptorManager
    
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
        let foregroundSessionManager = VimeoSessionManager.defaultSessionManager(authTokenBlock: authTokenBlock)
        self.deletionManager = VideoDeletionManager(sessionManager: foregroundSessionManager)

        self.descriptorManager = ReachableDescriptorManager(name: self.name, backgroundSessionIdentifier: backgroundSessionIdentifier, authTokenBlock: authTokenBlock)
    }
    
    // MARK: Public API

    func uploadVideo(descriptor: T)
    {
        self.descriptorManager.addDescriptor(descriptor.progressDescriptor)
    }

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
}
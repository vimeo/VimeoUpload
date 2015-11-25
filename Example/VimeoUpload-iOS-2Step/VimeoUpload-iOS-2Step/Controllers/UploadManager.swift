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
    
    private let sessionManager: VimeoSessionManager
    private let descriptorManager: DescriptorManager
    private let deletionManager: DeletionManager
    private let reporter: UploadReporter = UploadReporter()
    
    init()
    {
        self.sessionManager = VimeoSessionManager.backgroundSessionManager("com.vimeo.upload", authToken: "caf4648129ec56e580175c4b45cce7fc")
        self.descriptorManager = DescriptorManager(sessionManager: self.sessionManager, name: "uploader", delegate: self.reporter)
        self.deletionManager = DeletionManager(sessionManager: ForegroundSessionManager.sharedInstance, retryCount: 2)
    }
    
    // MARK: Public API
    
    func applicationDidFinishLaunching()
    {
        // Do nothing at the moment
    }
    
    func handleEventsForBackgroundURLSession(identifier: String, completionHandler: VoidBlock) -> Bool
    {
        return self.descriptorManager.handleEventsForBackgroundURLSession(identifier, completionHandler: completionHandler)
    }
    
    func uploadVideoWithUrl(url: NSURL, uploadTicket: VIMUploadTicket)
    {
        let descriptor = SimpleUploadDescriptor(url: url, uploadTicket: uploadTicket)
        descriptor.identifier = uploadTicket.video!.uri
        
        self.descriptorManager.addDescriptor(descriptor)
    }
    
    // TODO: this progress object isn't set right away on start, race condition, need to resolve
    func uploadProgressForVideoUri(videoUri: String) -> NSProgress?
    {
        if let descriptor = self.descriptorForVideoUri(videoUri)
        {
            return descriptor.progress
        }
        
        return nil
    }
    
    func uploadErrorForVideoUri(videoUri: String) -> NSError?
    {
        if let descriptor = self.descriptorForVideoUri(videoUri)
        {
            return descriptor.error
        }
        
        return nil
    }
    
    func cancelUploadWithVideoUri(videoUri: String)
    {
        if let descriptor = self.descriptorForVideoUri(videoUri)
        {
            descriptor.cancel(self.sessionManager)
        }

        self.deleteVideoWithUri(videoUri)
    }

    func deleteVideoWithUri(videoUri: String)
    {
        self.deletionManager.deleteVideoWithUri(videoUri)
    }
    
    // MARK: Private API
    
    private func descriptorForVideoUri(videoUri: String) -> SimpleUploadDescriptor?
    {
        let descriptor = self.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
            if let descriptor = descriptor as? SimpleUploadDescriptor, let currentVideoUri = descriptor.uploadTicket.video?.uri
            {
                return videoUri == currentVideoUri
            }
            
            return false
        })
        
        return descriptor as? SimpleUploadDescriptor
    }
}

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
    
    private let BackgroundSessionIdentifier = "com.vimeo.upload"
    private let DescriptorManagerName = "uploader"
    private let BasicUserToken = "3e9dae312853936216aba3ce56cf5066"
    private let ProUserToken = "caf4648129ec56e580175c4b45cce7fc"
    
    // MARK:
    
    private let sessionManager: VimeoSessionManager
    private let descriptorManager: DescriptorManager
    private let connectivityManager: ConnectivityManager
    private let deletionManager: VideoDeletionManager
    
    // MARK:
    
    private let reporter = UploadReporter()
    
    // MARK:
    // MARK: Initialization
    
    override init()
    {
        self.sessionManager = VimeoSessionManager.backgroundSessionManager(identifier: BackgroundSessionIdentifier, authToken: BasicUserToken)
        self.descriptorManager = DescriptorManager(sessionManager: self.sessionManager, name: DescriptorManagerName, delegate: self.reporter)
        self.connectivityManager = ConnectivityManager(descriptorManager: self.descriptorManager)
        self.deletionManager = VideoDeletionManager(sessionManager: ForegroundSessionManager.sharedInstance, retryCount: 2)
        
        super.init()
    }
    
    // MARK: Public API - Background Session
    
    func applicationDidFinishLaunching()
    {
        // Do nothing at the moment
    }
    
    func handleEventsForBackgroundURLSession(identifier identifier: String, completionHandler: VoidBlock) -> Bool
    {
        return self.descriptorManager.handleEventsForBackgroundURLSession(identifier: identifier, completionHandler: completionHandler)
    }
    
    // MARK: Public API - Uploads
    
    func allowsCellularUpload(allows: Bool)
    {
        self.connectivityManager.allowsCellularUpload = allows
    }

    // We need a reference (via the assetIdentifier) to the original asset so that we can retry failed uploads
    func uploadVideo(url url: NSURL, assetIdentifier: String, videoSettings: VideoSettings?)
    {
        let descriptor = UploadDescriptor(url: url, assetIdentifier: assetIdentifier, videoSettings: videoSettings)
        descriptor.identifier = assetIdentifier
        
        self.descriptorManager.addDescriptor(descriptor)
    }
    
//    func retryUpload(descriptor descriptor: UploadDescriptor, url: NSURL)
//    {
//        let videoSettings = descriptor.videoSettings
//        let assetIdentifier = descriptor.assetIdentifier
//        
//        let newDescriptor = UploadDescriptor(url: url, assetIdentifier: assetIdentifier, videoSettings: videoSettings)
//        newDescriptor.identifier = assetIdentifier
//        
//        self.descriptorManager.addDescriptor(newDescriptor)
//    }
    
    func deleteUpload(assetIdentifier assetIdentifier: String)
    {
        if let descriptor = self.uploadDescriptorForAssetIdentifier(assetIdentifier)
        {
            descriptor.cancel(sessionManager: self.sessionManager)
        
            if let videoUri = descriptor.videoUri
            {
                self.deletionManager.deleteVideoWithUri(videoUri) // Delete the video from the server if upload completed
            }
        }
    }
    
    func uploadDescriptorForAssetIdentifier(assetIdentifier: String) -> UploadDescriptor?
    {
        // Check active descriptors
        let descriptor = self.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
            
            if let descriptor = descriptor as? UploadDescriptor
            {
                return assetIdentifier == descriptor.assetIdentifier
            }
            
            return false
        })
        
        return descriptor as? UploadDescriptor
    }    
}

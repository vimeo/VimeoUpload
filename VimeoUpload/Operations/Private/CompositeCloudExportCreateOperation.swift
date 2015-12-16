//
//  CompositeCloudExportCreateOperation.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/9/15.
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
import AVFoundation
import Photos

// This flow encapsulates the following steps:

// 1. Perorm a CompositeCloudExportOperation
//// 1. If inCloud, download
//// 2. Export (check disk space within this step)
//// 3. Check weekly quota

// 2. Create video record

@available(iOS 8.0, *)
class CompositeCloudExportCreateOperation: ConcurrentOperation
{    
    let me: VIMUser
    let phAsset: PHAsset
    let sessionManager: VimeoSessionManager
    var videoSettings: VideoSettings?
    private let operationQueue: NSOperationQueue

    // MARK:
    
    var downloadProgressBlock: ProgressBlock?
    var exportProgressBlock: ProgressBlock?

    // MARK: 
    
    private(set) var url: NSURL?
    private(set) var uploadTicket: VIMUploadTicket?
    private(set) var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .Finished
            }
        }
    }

    // MARK: Initialization
    
    init(me: VIMUser, phAsset: PHAsset, sessionManager: VimeoSessionManager, videoSettings: VideoSettings? = nil)
    {
        self.me = me
        self.phAsset = phAsset
        self.sessionManager = sessionManager
        self.videoSettings = videoSettings
        
        self.operationQueue = NSOperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Overrides
    
    override func main()
    {
        if self.cancelled
        {
            return
        }
        
        self.performCloudExportOperation()
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
        
        if let url = self.url
        {
            NSFileManager.defaultManager().deleteFileAtURL(url)
        }
    }
    
    // MARK: Private API
    
    private func performCloudExportOperation()
    {
        let operation = CompositeCloudExportOperation(me: self.me, phAsset: self.phAsset)
        
        operation.downloadProgressBlock = { [weak self] (progress: Double) -> Void in
            self?.downloadProgressBlock?(progress: progress)
        }
        
        operation.exportProgressBlock = { [weak self] (progress: Double) -> Void in
            self?.exportProgressBlock?(progress: progress)
        }
        
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
                    strongSelf.error = error
                }
                else
                {
                    let url = operation.result!
                    strongSelf.createVideo(url: url)
                }
            })
        }

        self.operationQueue.addOperation(operation)
    }
    
    private func createVideo(url url: NSURL)
    {
        let videoSettings = self.videoSettings

        let operation = CreateVideoOperation(sessionManager: self.sessionManager, url: url, videoSettings: videoSettings)
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
                    strongSelf.error = error
                }
                else
                {
                    strongSelf.url = url
                    strongSelf.uploadTicket = operation.result!
                    strongSelf.state = .Finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
}
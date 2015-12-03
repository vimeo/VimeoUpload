//
//  RetryUploadOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/2/15.
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

// This flow encapsulates the following steps:

// 1. Perorm a CompositeMeQuotaOperation
//// 1. Request me
//// 2. Check daily quota
//// 3. If non iCloud asset, check approximate weekly quota
//// 4. If non iCloud asset, check approximate disk space

// 2. Perform a CompositeCloudExportCreateOperation
//// 1. Perorm a CompositeCloudExportOperation
////// 1. If inCloud, download
////// 2. Export (check disk space within this step)
////// 3. Check weekly quota
//// 2. Create video record

class RetryUploadOperation: ConcurrentOperation
{
    private let sessionManager: VimeoSessionManager
    private let avAsset: AVAsset
    private let operationQueue: NSOperationQueue
    
    // MARK: 
    
    private var me: VIMUser?

    // MARK:
    
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
    
    init(sessionManager: VimeoSessionManager, avAsset: AVAsset)
    {
        self.sessionManager = sessionManager
        self.avAsset = avAsset
        
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
        
        self.performCompositeQuotaOperation()
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Private API
    
    private func performCompositeQuotaOperation()
    {
        let operation = CompositeMeQuotaOperation(sessionManager: ForegroundSessionManager.sharedInstance, avAsset: self.avAsset)
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if strongSelf.cancelled
                {
                    return
                }
                
                if let error = operation.error
                {
                    strongSelf.error = error
                    
                    return
                }
                
                strongSelf.me = operation.me!
                strongSelf.performCompositeExportOperation()
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func performCompositeExportOperation()
    {
        let operation = CompositeCloudExportCreateOperation(me: self.me, phAssetContainer: phAssetContainer, sessionManager: self.sessionManager)
        
        operation.downloadProgressBlock = { (progress: Double) -> Void in
            print("Download progress (settings): \(progress)") // TODO: Dispatch to main thread
        }
        
        operation.exportProgressBlock = { (progress: Double) -> Void in
            print("Export progress (settings): \(progress)")
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
                    
                    return
                }

                strongSelf.url = operation.url!
                strongSelf.uploadTicket = operation.uploadTicket!
                strongSelf.startUpload()

                // TODO: video settings have already been applied?
                
                
                
                // TODO: ensure we have a reference to the asset
                
                // Initiate the retry
                UploadManager.sharedInstance.retryUpload(descriptor: descriptor)
                
                // And then reload the cell so that it reflects the state of the newly retried upload
                let videoUri = descriptor.uploadTicket.video!.uri!
                if let indexPath = strongSelf.indexPathForVideoUri(videoUri)
                {
                    strongSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }

            })
        }
        
        self.operationQueue.addOperation(operation)
    }
}

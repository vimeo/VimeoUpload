//
//  ALAssetExportQuotaCreateOperation.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Hanssen, Alfie on 12/22/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AssetsLibrary
import AVFoundation

// This flow encapsulates the following steps:

// 1. Perorm a ALAssetExportQuotaOperation
//// 1. Export (check disk space within this step)
//// 2. Check weekly quota

// 2. Create video record

class ALAssetExportQuotaCreateOperation: ConcurrentOperation
{
    let me: VIMUser
    let alAsset: ALAsset
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
    
    init(me: VIMUser, alAsset: ALAsset, sessionManager: VimeoSessionManager, videoSettings: VideoSettings? = nil)
    {
        self.me = me
        self.alAsset = alAsset
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
        
        self.performExportQuotaOperation()
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

    private func performExportQuotaOperation()
    {
        let operation = ALAssetExportQuotaOperation(me: self.me, alAsset: self.alAsset)
        
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

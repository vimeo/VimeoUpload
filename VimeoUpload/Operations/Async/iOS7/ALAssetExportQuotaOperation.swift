//
//  ALAssetExportQuotaOperation.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Hanssen, Alfie on 12/22/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AssetsLibrary
import AVFoundation

// This flow encapsulates the following steps:
// 1. Export (check disk space within this step)
// 2. Check weekly quota

class ALAssetExportQuotaOperation: ConcurrentOperation
{
    let me: VIMUser
    let alAsset: ALAsset
    private let operationQueue: NSOperationQueue
    
    var downloadProgressBlock: ProgressBlock?
    var exportProgressBlock: ProgressBlock?
    
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
    private(set) var result: NSURL?
    
    init(me: VIMUser, alAsset: ALAsset)
    {
        self.me = me
        self.alAsset = alAsset
        
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
        
        self.performExport()
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
        
        if let url = self.result
        {
            NSFileManager.defaultManager().deleteFileAtURL(url)
        }
    }
    
    // MARK: Private API

    private func performExport()
    {
        let url = self.alAsset.defaultRepresentation().url()
        let avAsset = AVURLAsset(URL: url)

        let operation = ExportOperation(asset: avAsset)
        operation.progressBlock = { [weak self] (progress: Double) -> Void in // This block is called on a background thread
            
            if let progressBlock = self?.exportProgressBlock
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    progressBlock(progress: progress)
                })
            }
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
                    let url = operation.outputURL!
                    strongSelf.checkExactWeeklyQuota(url: url)
                }
                })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func checkExactWeeklyQuota(url url: NSURL)
    {
        let me = self.me
        let avUrlAsset = AVURLAsset(URL: url)
        
        let fileSize: NSNumber
        do
        {
            fileSize = try avUrlAsset.fileSize()
        }
        catch let error as NSError
        {
            self.error = error
            
            return
        }
        
        let operation = WeeklyQuotaOperation(user: me, filesize: fileSize.doubleValue)
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
                else if let result = operation.result where result == false
                {
                    strongSelf.error = NSError(domain: UploadErrorDomain.PHAssetCloudExportQuotaOperation.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed weekly quota."])
                }
                else
                {
                    strongSelf.result = url
                    strongSelf.state = .Finished
                }
                })
        }
        
        self.operationQueue.addOperation(operation)
    }
}

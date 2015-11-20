//
//  UploadPrepOperation.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/9/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//
//  Created by Hanssen, Alfie on 10/13/15.
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
// 1. If inCloud, download
// 2. Export (check disk space within this step)
// 3. Check weekly quota
// 4. Create video record

class SimpleVideoSettingsOperation: ConcurrentOperation
{
    private static let ErrorDomain = "SimpleVideoSettingsOperation"
    
    let me: VIMUser
    let phAssetContainer: PHAssetContainer
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

    init(me: VIMUser, phAssetContainer: PHAssetContainer)
    {
        self.me = me
        self.phAssetContainer = phAssetContainer
        
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

        if let asset = self.phAssetContainer.avAsset
        {
            self.export(asset)
        }
        else
        {
            self.downloadPHAssetExportSession()
        }
    }
    
    override func cancel()
    {
        super.cancel()
        
        print("VideoSettingsOperation cancelled")

        self.operationQueue.cancelAllOperations()
        
        if let url = self.result
        {
            self.deleteFile(url)
        }
    }
    
    // MARK: Private API
    
    private func downloadPHAssetExportSession()
    {
        let phAsset = self.phAssetContainer.phAsset
        let operation = PHAssetExportSessionOperation(phAsset: phAsset)
        operation.progressBlock = self.downloadProgressBlock
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
                    let exportSession = operation.result!
                    strongSelf.export(exportSession)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func export(exportSession: AVAssetExportSession)
    {
        let operation = AVAssetExportOperation(exportSession: exportSession)
        self.export(operation)
    }
    
    private func export(asset: AVAsset)
    {
        let operation = AVAssetExportOperation(asset: asset)
        self.export(operation)
    }
    
    private func export(operation: AVAssetExportOperation)
    {
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
                    strongSelf.result = operation.outputURL!

                    let avUrlAsset = AVURLAsset(URL: strongSelf.result!)
                    strongSelf.checkExactWeeklyQuota(avUrlAsset)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func checkExactWeeklyQuota(avUrlAsset: AVURLAsset)
    {
        let filesize: NSNumber?
        do
        {
            filesize = try avUrlAsset.fileSize()
        }
        catch let error as NSError
        {
            self.error = error
            
            return
        }
        
        guard let size = filesize else
        {
            self.error = NSError(domain: SimpleVideoSettingsOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Exact filesize calculation failed, filesize is nil."])
        
            return
        }
        
        let operation = WeeklyQuotaOperation(user: self.me, filesize: size.doubleValue)
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
                    strongSelf.error = NSError(domain: SimpleVideoSettingsOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed weekly quota."])
                }
                else
                {
                    strongSelf.state = .Finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
        
    // MARK: Private API
    
    private func deleteFile(url: NSURL)
    {
        if let path = url.path where NSFileManager.defaultManager().fileExistsAtPath(path)
        {
            do
            {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            }
            catch let error as NSError
            {
                assertionFailure("Error removing exported file \(error)")
            }
        }
    }
}
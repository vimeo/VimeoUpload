//
//  MeQuotaOperation.swift
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

// This flow encapsulates the following steps:
// 1. Request me
// 2. Fulfill asset selection
// 3. Check daily quota
// 4. If non iCloud asset, check approximate weekly quota
// 5. If non iCloud asset, check approximate disk space

class MeQuotaOperation: ConcurrentOperation
{    
    let sessionManager: VimeoSessionManager
    
    private(set) var me: VIMUser?
    private let operationQueue: NSOperationQueue
    
    private var avAsset: AVAsset?
    private var selectionFulfilled: Bool = false

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
    
    init(sessionManager: VimeoSessionManager, me: VIMUser? = nil)
    {
        self.sessionManager = sessionManager
        self.me = me
        
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

        if let _ = self.me
        {
            self.proceedIfMeAndSelectionFulfilled()
        }
        else
        {
            self.requestMe()
        }
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
    }

    // MARK: Public API
    
    // If selection is fulfilled with a nil AVAsset,
    // Then we're dealing with an iCloud asset
    // This is ok, but download of iCloud asset is not handled by this workflow
    
    func fulfillSelection(avAsset avAsset: AVAsset?)
    {
        if self.selectionFulfilled == true
        {
            assertionFailure("Attempt to fulfill selection that has already been fulfilled")
            
            return
        }
        
        if self.cancelled
        {
            return
        }

        if let _ = self.error
        {
            return
        }

        self.avAsset = avAsset
        self.selectionFulfilled = true
        
        self.proceedIfMeAndSelectionFulfilled()
    }
    
    // MARK: Private API
    
    private func requestMe()
    {
        let operation = MeOperation(sessionManager: self.sessionManager)
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
                    strongSelf.me = operation.result!
                    strongSelf.proceedIfMeAndSelectionFulfilled()
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func proceedIfMeAndSelectionFulfilled()
    {
        if let _ = self.error
        {
            return
        }
        
        guard let _ = self.me where self.selectionFulfilled == true else
        {
            return
        }
        
        self.checkDailyQuota()
    }
    
    private func checkDailyQuota()
    {
        let me = self.me!
        
        let operation = DailyQuotaOperation(user: me)
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
                
                // Do not check error, allow to pass [AH]

                if let result = operation.result where result == false
                {
                    strongSelf.error = NSError.errorWithDomain(UploadErrorDomain.MeQuotaOperation.rawValue, code: UploadLocalErrorCode.DailyQuotaException.rawValue, description: "Upload would exceed daily quota.")
                }
                else
                {
                    if strongSelf.avAsset != nil
                    {
                        strongSelf.checkApproximateWeeklyQuota() // If the asset is not nil, then we can perform the the MB-based checks
                    }
                    else
                    {
                        strongSelf.state = .Finished // If the asset is nil, then it's in iCloud and we don't yet have access to the filesize
                    }
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }

   private func checkApproximateWeeklyQuota()
    {
        let me = self.me!
        let avAsset = self.avAsset!
        avAsset.approximateFileSize { [weak self] (value) -> Void in

            guard let strongSelf = self else
            {
                return
            }

            let operation = WeeklyQuotaOperation(user: me, fileSize: value)
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
                    
                    // Do not check error, allow to pass [AH]

                    if let result = operation.result where result.success == false
                    {
                        let userInfo = [UploadErrorKey.FileSize.rawValue: result.fileSize, UploadErrorKey.AvailableSpace.rawValue: result.availableSpace]
                        strongSelf.error = NSError.errorWithDomain(UploadErrorDomain.MeQuotaOperation.rawValue, code: UploadLocalErrorCode.WeeklyQuotaException.rawValue, description: "Upload would exceed approximate weekly quota.").errorByAddingUserInfo(userInfo)
                    }
                    else
                    {
                        strongSelf.checkApproximateDiskSpace(fileSize: value)
                    }
                })
            }
            
            strongSelf.operationQueue.addOperation(operation)
        }
    }

    private func checkApproximateDiskSpace(fileSize fileSize: Float64)
    {
        let operation = DiskSpaceOperation(fileSize: fileSize)
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
                
                // Do not check error, allow to pass [AH]

                if let result = operation.result where result.success == false
                {
                    let userInfo = [UploadErrorKey.FileSize.rawValue: result.fileSize, UploadErrorKey.AvailableSpace.rawValue: result.availableSpace]
                    strongSelf.error = NSError.errorWithDomain(UploadErrorDomain.MeQuotaOperation.rawValue, code: UploadLocalErrorCode.DiskSpaceException.rawValue, description: "Not enough approximate disk space to export asset.").errorByAddingUserInfo(userInfo)
                }
                else
                {
                    strongSelf.state = .Finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
}
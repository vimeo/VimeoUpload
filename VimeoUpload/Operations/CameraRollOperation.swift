//
//  UploadPrepOperation.swift
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
// 1. Fulfill asset selection
// 2. Check daily quota
// 3. If asset, check weekly quota
// 4. If asset, check disk space

class CameraRollOperation: ConcurrentOperation
{
    private static let ErrorDomain = "CameraRollOperationErrorDomain"
    
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
    
    convenience init(sessionManager: VimeoSessionManager)
    {
        self.init(sessionManager: sessionManager, me: nil)
    }

    init(sessionManager: VimeoSessionManager, me: VIMUser?)
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
        
        print("CameraRollOperation cancelled")
        
        self.operationQueue.cancelAllOperations()
    }

    // MARK: Public API
    
    // If selection is fulfilled with a nil AVAsset,
    // Then we're dealing with an iCloud asset
    // This is ok, but download of iCloud asset is not handled by this workflow
    
    func fulfillSelection(avAsset: AVAsset?)
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
        
        if self.avAsset == nil
        {
            self.state = .Finished
        }
        else
        {
            self.checkDailyQuota()
        }
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
                
                if let error = operation.error
                {
                    strongSelf.error = error
                }
                else if let result = operation.result where result == false
                {
                    strongSelf.error = NSError(domain: CameraRollOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed approximate daily quota."])
                }
                else
                {
                    strongSelf.checkApproximateWeeklyQuota()
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }

   private func checkApproximateWeeklyQuota()
    {
        let me = self.me!
        let avAsset = self.avAsset!
        let filesize = avAsset.approximateFileSize()
        
        let operation = WeeklyQuotaOperation(user: me, filesize: filesize)
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
                    strongSelf.error = NSError(domain: CameraRollOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed approximate weekly quota."])
                }
                else
                {
                    strongSelf.checkApproximateDiskSpace()
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }

    private func checkApproximateDiskSpace()
    {
        let filesize = self.avAsset!.approximateFileSize()
        
        let operation = DiskSpaceOperation(filesize: filesize)
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
                    strongSelf.error = NSError(domain: CameraRollOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Not enough approximate disk space to export asset."])
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
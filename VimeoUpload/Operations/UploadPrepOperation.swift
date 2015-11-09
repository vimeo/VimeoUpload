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

class UploadPrepOperation: ConcurrentOperation
{
    private static let ErrorDomain = "UploadPrepOperationErrorDomain"
    
    private let sessionManager: VimeoSessionManager
    private let operationQueue: NSOperationQueue

    private var me: VIMUser?
    private var avAsset: AVAsset?
    private var didReceiveSelection: Bool = false // For debugging

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
    {
        didSet
        {
            if self.result != nil
            {
                self.state = .Finished
            }
        }
    }
    
    init(sessionManager: VimeoSessionManager)
    {
        self.sessionManager = sessionManager
        
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

        let operation = MeOperation(sessionManager: self.sessionManager)
        operation.completionBlock = { [weak self] () -> Void in
            
            // TODO: which thread is this called on?

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
                strongSelf.proceedIfMeAndAVAssetExist()
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
    }

    // MARK: Public API
    
    func retryableOperation() -> UploadPrepOperation
    {
        let operation = UploadPrepOperation(sessionManager: self.sessionManager)
        operation.me = self.me
        operation.avAsset = self.avAsset
        
        return operation
    }
    
    func selectPHAssetContainer(phAssetContainer: PHAssetContainer)
    {
        if self.didReceiveSelection == true
        {
            assertionFailure("Attempt to add selection to workflow that already has a selection")
            
            return
        }
        
        if self.cancelled
        {
            return
        }

        self.didReceiveSelection = true
    
        if let avAsset = phAssetContainer.avAsset
        {
            self.avAsset = avAsset
            self.proceedIfMeAndAVAssetExist()
        }
        else
        {
            self.downloadPHAsset(phAssetContainer.phAsset)
        }
    }
    
    // MARK: Private API
    
    private func downloadPHAsset(phAsset: PHAsset)
    {
        let operation = PHAssetDownloadOperation(phAsset: phAsset)
        
        operation.progressBlock = { [weak self] (progress: Double) -> Void in
            
            // TODO: which thread is this called on?
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in

                guard let _ = self else
                {
                    return
                }

                print("Download: \(progress)")
            })
        }
        
        operation.completionBlock = { [weak self] () -> Void in
            
            // TODO: which thread is this called on?
            
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
                strongSelf.avAsset = operation.result!
                strongSelf.proceedIfMeAndAVAssetExist()
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func proceedIfMeAndAVAssetExist()
    {
        if let _ = self.error
        {
            return
        }
        
        guard let _ = self.me, let _ = self.avAsset else
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
                strongSelf.error = NSError(domain: UploadPrepOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed approximate daily quota."])
            }
            else
            {
                strongSelf.checkApproximateWeeklyQuota()
            }
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
                strongSelf.error = NSError(domain: UploadPrepOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed approximate weekly quota."])
            }
            else
            {
                strongSelf.checkApproximateDiskSpace()
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func checkApproximateDiskSpace()
    {
        let filesize = self.avAsset!.approximateFileSize()
        
        let operation = DiskSpaceOperation(filesize: filesize)
        operation.completionBlock = { [weak self] () -> Void in
            
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
                strongSelf.error = NSError(domain: UploadPrepOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Not enough approximate disk space to export asset."])
            }
            else
            {
                strongSelf.exportAsset()
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func exportAsset()
    {
        let avAsset = self.avAsset!
        
        let operation = AVAssetExportOperation(asset: avAsset)
        operation.progressBlock = { [weak self] (progress: Double) -> Void in
           
            // TODO: which thread is this called on?
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let _ = self else
                {
                    return
                }
                
                print("Export: \(progress)")
            })
        }

        operation.completionBlock = { [weak self] () -> Void in
            
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
                let outputURL = operation.outputURL!
                let avUrlAsset = AVURLAsset(URL: outputURL)
                strongSelf.checkExactWeeklyQuota(avUrlAsset)
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func checkExactWeeklyQuota(avUrlAsset: AVURLAsset)
    {
        let me = self.me!

        let filesize: NSNumber
        do
        {
            filesize = try self.exactFilesize(avUrlAsset)
        }
        catch let error as NSError
        {
            self.error = error
            
            return
        }
        
        let operation = WeeklyQuotaOperation(user: me, filesize: filesize.doubleValue)
        operation.completionBlock = { [weak self] () -> Void in
            
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
                strongSelf.error = NSError(domain: UploadPrepOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload would exceed weekly quota."])
            }
            else
            {
                strongSelf.checkExactDiskSpace(avUrlAsset)
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func checkExactDiskSpace(avUrlAsset: AVURLAsset)
    {
        let filesize: NSNumber
        do
        {
            filesize = try self.exactFilesize(avUrlAsset)
        }
        catch let error as NSError
        {
            self.error = error
            
            return
        }

        let operation = DiskSpaceOperation(filesize: filesize.doubleValue)
        operation.completionBlock = { [weak self] () -> Void in
            
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
                strongSelf.error = NSError(domain: UploadPrepOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Not enough disk space to export asset."])
            }
            else
            {
                strongSelf.result = avUrlAsset.URL
            }
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    // MARK: Utilities
    
    private func exactFilesize(avUrlAsset: AVURLAsset) throws -> NSNumber
    {
        let filesize = try avUrlAsset.fileSize()

        if filesize == nil
        {
            throw NSError(domain: UploadPrepOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Exact filesize calculation failed because filesize is nil."])
        }
        
        return filesize!
    }
}
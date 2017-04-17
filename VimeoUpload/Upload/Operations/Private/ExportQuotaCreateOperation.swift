//
//  ExportQuotaCreateOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/22/15.
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
import VimeoNetworking

open class ExportQuotaCreateOperation: ConcurrentOperation
{
    let me: VIMUser
    let sessionManager: VimeoSessionManager
    open var videoSettings: VideoSettings?
    let operationQueue: OperationQueue
    
    // MARK:

    open var downloadProgressBlock: ProgressBlock?
    open var exportProgressBlock: ExportProgressBlock?
    
    // MARK:
    
    open var url: URL?
    open var uploadTicket: VIMUploadTicket?
    open var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .finished
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(me: VIMUser, sessionManager: VimeoSessionManager, videoSettings: VideoSettings? = nil)
    {
        self.me = me
        self.sessionManager = sessionManager
        self.videoSettings = videoSettings
        
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
    }
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Overrides
    
    override open func main()
    {
        if self.isCancelled
        {
            return
        }
        
        let operation = self.makeExportQuotaOperation(self.me)!
        self.performExportQuotaOperation(operation)
    }
    
    override open func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
        
        if let url = self.url
        {
            FileManager.default.deleteFile(at: url)
        }
    }
    
    // MARK: Public API
    
    func makeExportQuotaOperation(_ me: VIMUser) -> ExportQuotaOperation?
    {
        assertionFailure("Subclasses must override")
        
        return nil
    }
    
    // MARK: Private API

    private func performExportQuotaOperation(_ operation: ExportQuotaOperation)
    {
        operation.downloadProgressBlock = { [weak self] (progress: Double) -> Void in
            self?.downloadProgressBlock?(progress)
        }
        
        operation.exportProgressBlock = { [weak self] (exportSession: AVAssetExportSession, progress: Double) -> Void in
            self?.exportProgressBlock?(exportSession, progress)
        }
        
        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
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
    
    private func createVideo(url: URL)
    {
        let videoSettings = self.videoSettings
        
        let operation = CreateVideoOperation(sessionManager: self.sessionManager, url: url, videoSettings: videoSettings)
        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    if let fileSize = try? AVURLAsset(url: url).fileSize().doubleValue, let availableSpace = strongSelf.me.uploadQuota?.sizeQuota?.free?.doubleValue
                    {
                        let userInfo = [UploadErrorKey.FileSize.rawValue: fileSize, UploadErrorKey.AvailableSpace.rawValue: availableSpace]
                        strongSelf.error = error.error(byAddingUserInfo: userInfo)
                    }
                    else
                    {
                        strongSelf.error = error
                    }
                }
                else
                {
                    strongSelf.url = url
                    strongSelf.uploadTicket = operation.result!
                    strongSelf.state = .finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
}

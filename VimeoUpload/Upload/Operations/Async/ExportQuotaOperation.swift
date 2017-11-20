//
//  ExportQuotaOperation.swift
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
import Photos

public typealias ExportProgressBlock = (AVAssetExportSession, Double) -> Void

open class ExportQuotaOperation: ConcurrentOperation
{
    let operationQueue: OperationQueue

    open var downloadProgressBlock: ProgressBlock?
    open var exportProgressBlock: ExportProgressBlock?
    
    private let phAsset: PHAsset

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
    open var result: URL?
    
    public init(phAsset: PHAsset)
    {
        self.phAsset = phAsset
        
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
        
        super.init()
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
        
        self.requestExportSession()
    }
    
    override open func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
        
        if let url = self.result
        {
            FileManager.default.deleteFile(at: url)
        }
    }
    
    // MARK: Public API

    func requestExportSession()
    {
        let operation = PHAssetExportSessionOperation(phAsset: self.phAsset)
        operation.progressBlock = self.downloadProgressBlock
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
                    let exportSession = operation.result!
                    let exportOperation = ExportOperation(exportSession: exportSession)
                    strongSelf.performExport(exportOperation: exportOperation)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    func performExport(exportOperation: ExportOperation)
    {
        exportOperation.progressBlock = { [weak self] (progress: Double) -> Void in // This block is called on a background thread
            
            if let progressBlock = self?.exportProgressBlock
            {
                DispatchQueue.main.async(execute: { () -> Void in
                    progressBlock(exportOperation.exportSession, progress)
                })
            }
        }
        
        exportOperation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if exportOperation.isCancelled == true
                {
                    return
                }
                
                if let error = exportOperation.error
                {
                    strongSelf.error = error
                }
                else
                {
                    let url = exportOperation.outputURL!
                    strongSelf.result = url
                    strongSelf.state = .finished
                }
            })
        }
        
        self.operationQueue.addOperation(exportOperation)
    }
}

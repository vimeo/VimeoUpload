//
//  RetryUploadOperation.swift
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
import VimeoNetworking
import AVFoundation
import Photos

public class RetryUploadOperation: ConcurrentOperation
{
    private let sessionManager: VimeoSessionManager
    let operationQueue: OperationQueue
    
    // MARK:
    
    public var downloadProgressBlock: ProgressBlock?
    public var exportProgressBlock: ProgressBlock?
    
    // MARK:
    
    private let phAsset: PHAsset

    private(set) public var url: URL?
    private(set) public var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .finished
            }
        }
    }
    
    private let documentsFolderURL: URL
    
    // MARK: - Initialization
    
    public init(phAsset: PHAsset, sessionManager: VimeoSessionManager, documentsFolderURL: URL)
    {
        self.phAsset = phAsset
        
        self.sessionManager = sessionManager
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
        
        self.documentsFolderURL = documentsFolderURL
        
        super.init()
    }
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Overrides
    
    override public func main()
    {
        if self.isCancelled
        {
            return
        }
        
        let operation = ExportSessionExportOperation(phAsset: self.phAsset, documentsFolderURL: self.documentsFolderURL)
        self.perform(exportSessionExportOperation: operation)
    }
    
    override public func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Private API
    
    private func perform(exportSessionExportOperation operation: ExportSessionExportOperation)
    {
        operation.downloadProgressBlock = { [weak self] (progress: Double) -> Void in
            self?.downloadProgressBlock?(progress)
        }
        
        operation.exportProgressBlock = { [weak self] (exportSession: AVAssetExportSession, progress: Double) -> Void in
            self?.exportProgressBlock?(progress)
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
                    strongSelf.url = operation.result!
                    strongSelf.state = .finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
}

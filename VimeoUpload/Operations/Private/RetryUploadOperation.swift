//
//  RetryUploadOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/22/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

class RetryUploadOperation: ConcurrentOperation
{
    private let sessionManager: VimeoSessionManager
    let operationQueue: NSOperationQueue
    
    // MARK:
    
    var downloadProgressBlock: ProgressBlock?
    var exportProgressBlock: ProgressBlock?
    
    // MARK:
    
    var url: NSURL?
    var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .Finished
            }
        }
    }
    
    // MARK: - Initialization
    
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
        
        self.performMeQuotaOperation()
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Private API
    
    private func performMeQuotaOperation()
    {
        let operation = MeQuotaOperation(sessionManager: self.sessionManager)
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
                }
                else
                {
                    let user = operation.me!
                    let exportQuotaOperation = strongSelf.makeExportQuotaOperation(user: user)!
                    strongSelf.performExportQuotaOperation(exportQuotaOperation)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
        
        operation.fulfillSelection(avAsset: nil)
    }
    
    private func performExportQuotaOperation(operation: ExportQuotaOperation)
    {
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
                    strongSelf.url = operation.result!
                    strongSelf.state = .Finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }

    // MARK: Public API
    
    func makeExportQuotaOperation(user user: VIMUser) -> ExportQuotaOperation?
    {
        assertionFailure("Subclasses must override")
        
        return nil
    }
}

//
//  PHAssetCloudExportQuotaOperation.swift
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

import Photos

// This flow encapsulates the following steps:
// 1. If inCloud, download
// 2. Export (check disk space within this step)
// 3. Check weekly quota

class PHAssetCloudExportQuotaOperation: ExportQuotaOperation
{    
    let phAsset: PHAsset

    init(me: VIMUser, phAsset: PHAsset)
    {
        self.phAsset = phAsset

        super.init(me: me)
    }
    
    // MARK: Subclass Overrides
    
    override func requestExportSession()
    {
        let operation = PHAssetExportSessionOperation(phAsset: self.phAsset)
        operation.progressBlock = super.downloadProgressBlock
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
                    let exportOperation = ExportOperation(exportSession: exportSession)
                    strongSelf.performExport(exportOperation: exportOperation)
                }
            })
        }

        self.operationQueue.addOperation(operation)
    }
}
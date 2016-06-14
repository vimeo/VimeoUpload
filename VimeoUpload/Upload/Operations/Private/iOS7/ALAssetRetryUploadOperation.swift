//
//  ALAssetRetryUploadOperation.swift
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
import AssetsLibrary
import VimeoNetworking

// This flow encapsulates the following steps:

// 1. Perorm a MeQuotaOperation
// 2. Perform a ALAssetExportQuotaOperation

public class ALAssetRetryUploadOperation: RetryUploadOperation
{
    private let alAsset: ALAsset
    
    // MARK: - Initialization
    
    init(sessionManager: VimeoSessionManager, alAsset: ALAsset)
    {
        self.alAsset = alAsset
        
        super.init(sessionManager: sessionManager)
    }
    
    // MARK: Overrides
    
    override func makeExportQuotaOperation(user user: VIMUser) -> ExportQuotaOperation?
    {
        return ALAssetExportQuotaOperation(me: user, alAsset: self.alAsset)
    }
}

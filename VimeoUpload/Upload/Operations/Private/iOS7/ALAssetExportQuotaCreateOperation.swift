//
//  ALAssetExportQuotaCreateOperation.swift
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

// 1. Perorm a ALAssetExportQuotaOperation
// 2. Create video record

class ALAssetExportQuotaCreateOperation: ExportQuotaCreateOperation
{
    let alAsset: ALAsset
    
    // MARK: - Initialization
    
    init(me: VIMUser, alAsset: ALAsset, sessionManager: VimeoSessionManager, videoSettings: VideoSettings? = nil)
    {
        self.alAsset = alAsset

        super.init(me: me, sessionManager: sessionManager, videoSettings: videoSettings)
    }
    
    // MARK: Overrides

    override func makeExportQuotaOperation(me: VIMUser) -> ExportQuotaOperation?
    {
        return ALAssetExportQuotaOperation(me: me, alAsset: self.alAsset)
    }
}

//
//  ALAssetExportQuotaOperation.swift
//  VimeoUpload-iOS-2Step
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

import AVFoundation
import VimeoNetworking

#if os(iOS)
    import AssetsLibrary
#endif

// This flow encapsulates the following steps:
// 1. Export (check disk space within this step)
// 2. Check weekly quota

public class ALAssetExportQuotaOperation: ExportQuotaOperation
{
    let alAsset: ALAsset
    
    init(me: VIMUser, alAsset: ALAsset)
    {
        self.alAsset = alAsset
     
        super.init(me: me)
    }

    // MARK: Subclass Overrides
    
    override func requestExportSession()
    {
        let url = self.alAsset.defaultRepresentation().url()
        let avAsset = AVURLAsset(URL: url)
     
        let exportOperation = ExportOperation(asset: avAsset)
        self.performExport(exportOperation: exportOperation)
    }
}

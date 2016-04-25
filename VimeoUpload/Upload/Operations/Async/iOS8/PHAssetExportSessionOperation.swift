//
//  PHAssetExportSessionOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 11/10/15.
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
import Photos

@available(iOS 8, *)
class PHAssetExportSessionOperation: ConcurrentOperation
{
    private let phAsset: PHAsset
    private let exportPreset: String
    
    private var requestID: PHImageRequestID?
    var progressBlock: ProgressBlock?
    
    private(set) var result: AVAssetExportSession?
    private(set) var error: NSError?
    
    // MARK: - Initialization
    
    deinit
    {
        self.cleanup()
    }
    
    init(phAsset: PHAsset, exportPreset: String = AVAssetExportPresetPassthrough)
    {
        self.phAsset = phAsset
        self.exportPreset = exportPreset
        
        super.init()
    }
    
    // MARK: Overrides
    
    override internal func main()
    {
        if self.cancelled
        {
            return
        }
        
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = true
        options.deliveryMode = .HighQualityFormat
        options.progressHandler = { [weak self] (progress: Double, error: NSError?, stop: UnsafeMutablePointer<ObjCBool>, info: [NSObject : AnyObject]?) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.requestID = nil
            
            if strongSelf.cancelled
            {
                return
            }
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            // We don't need to handle errors here, the same error will be delivered to the resultHandler below
            if let _ = error
            {
                strongSelf.progressBlock = nil
            }
            else if let info = info, let _ = info[PHImageErrorKey] as? NSError
            {
                strongSelf.progressBlock = nil
            }
            else
            {
                strongSelf.progressBlock?(progress: progress)
            }
        }
        
        self.requestID = PHImageManager.defaultManager().requestExportSessionForVideo(self.phAsset, options: options, exportPreset: self.exportPreset, resultHandler: { [weak self] (exportSession, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.requestID = nil
            
            if strongSelf.cancelled
            {
                return
            }
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                strongSelf.error = error.errorByAddingDomain(UploadErrorDomain.PHAssetExportSessionOperation.rawValue)
            }
            else if let exportSession = exportSession
            {
                strongSelf.result = exportSession
            }
            else
            {
                strongSelf.error = NSError.errorWithDomain(UploadErrorDomain.PHAssetExportSessionOperation.rawValue, code: nil, description: "Request for export session returned no error and no export session")
            }
            
            strongSelf.state = .Finished
        })
    }
    
    override internal func cancel()
    {
        super.cancel()
                
        self.cleanup()
    }
    
    // MARK: Private API
    
    private func cleanup()
    {
        self.progressBlock = nil
        
        if let requestID = self.requestID
        {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
            self.requestID = nil
        }
    }
}

//
//  PHAssetExportSessionOperation.swift
//  VimeoUpload-iOS-2Step
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
    private static let ErrorDomain = "PHAssetExportSessionOperationErrorDomain"

    private let phAsset: PHAsset
    private let exportPreset: String
    
    private var requestID: PHImageRequestID?
    var progressBlock: ProgressBlock?
    
    private(set) var result: AVAssetExportSession?
    private(set) var error: NSError?
    
    // MARK: Initialization
    
    deinit
    {
        self.cleanup()
    }
    
    init(phAsset: PHAsset, exportPreset: String = AVAssetExportPresetHighestQuality)
    {
        self.phAsset = phAsset
        self.exportPreset = exportPreset
        
        super.init()
    }
    
    // MARK: Overrides
    
    override func main()
    {
        if self.cancelled
        {
            return
        }
        
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = true
        options.deliveryMode = .HighQualityFormat
        options.progressHandler = { [weak self] (progress: Double, error: NSError?, stop: UnsafeMutablePointer<ObjCBool>, info: [NSObject : AnyObject]?) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
            
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
                
                // TODO: if an error is delivered here, will the completionHandler be called? Do we need to check these here?
                
                if let error = error
                {
                    strongSelf.error = error
                    strongSelf.state = .Finished
                }
                else if let info = info, let error = info[PHImageErrorKey] as? NSError
                {
                    strongSelf.error = error
                    strongSelf.state = .Finished
                }
                else
                {
                    strongSelf.progressBlock?(progress: progress)
                }
            })
        }
        
        self.requestID = PHImageManager.defaultManager().requestExportSessionForVideo(self.phAsset, options: options, exportPreset: self.exportPreset, resultHandler: { (exportSession, info) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
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
                    strongSelf.error = error
                }
                else if let exportSession = exportSession
                {
                    strongSelf.result = exportSession
                }
                else
                {
                    strongSelf.error = NSError(domain: PHAssetExportSessionOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Request for export session returned no error and no export session"])
                }
                
                strongSelf.state = .Finished
            })
        })
    }
    
    override func cancel()
    {
        super.cancel()
        
        print("PHAssetExportSessionOperation cancelled")
        
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

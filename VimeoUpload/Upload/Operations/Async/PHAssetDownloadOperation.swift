//
//  PHAssetDownloadOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
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

class PHAssetDownloadOperation: ConcurrentOperation
{    
    private let phAsset: PHAsset
    
    private var requestID: PHImageRequestID?
    var progressBlock: ProgressBlock?

    private(set) var result: AVAsset?
    private(set) var error: NSError?

    // MARK: - Initialization

    deinit
    {
        self.cleanup()
    }
    
    init(phAsset: PHAsset)
    {
        self.phAsset = phAsset
        
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
            
            if strongSelf.state == .Finished // Just in case
            {
                return
            }

            if let error = error
            {
                strongSelf.progressBlock = nil
                strongSelf.error = error.errorByAddingDomain(UploadErrorDomain.PHAssetDownloadOperation.rawValue)
                strongSelf.state = .Finished
            }
            else if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                strongSelf.progressBlock = nil
                strongSelf.error = error
                strongSelf.state = .Finished
            }
            else
            {
                strongSelf.progressBlock?(progress: progress)
            }
        }
        
        self.requestID = PHImageManager.defaultManager().requestAVAssetForVideo(self.phAsset, options: options) { [weak self] (asset, audioMix, info) -> Void in
            
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

            if strongSelf.state == .Finished // In case the state is changed to .Finished in the progressHandler above
            {
                return
            }

            if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                strongSelf.error = error.errorByAddingDomain(UploadErrorDomain.PHAssetDownloadOperation.rawValue)
            }
            else if let asset = asset
            {
                strongSelf.result = asset
            }
            else
            {
                strongSelf.error = NSError.errorWithDomain(UploadErrorDomain.PHAssetDownloadOperation.rawValue, code: nil, description: "Request for AVAsset returned no error and no asset.")
            }
            
            strongSelf.state = .Finished
        }
    }
    
    override func cancel()
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

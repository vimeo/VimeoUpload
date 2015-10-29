//
//  DiskSpaceOperation.swift
//  VIMUpload
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

@available(iOS 8, *)
class PHAssetOperation: ConcurrentOperation
{
    private let phAsset: PHAsset
    private var requestID: PHImageRequestID?
    
    var networkAccessAllowed = true
    var progressBlock: ProgressBlock?

    private(set) var avAsset: AVAsset?
    {
        didSet
        {
            if self.avAsset != nil
            {
                self.state = .Finished
            }
        }
    }
    
    private(set) var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .Finished
            }
        }
    }

    // MARK: Initialization

    deinit
    {
        self.progressBlock = nil

        if let requestID = self.requestID
        {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
        
            self.requestID = nil
        }
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
        
        // TODO: do we need to do an upfront check with options.networkAccessAllowed = false? [AH]
        
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = self.networkAccessAllowed;
        options.deliveryMode = .Automatic;
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

            if let error = error
            {
                // TODO: is this ok? It sets state to finished, is completion block then called as well? [AH]
                strongSelf.error = error.errorByAddingDomain(UploadErrorDomain.PHAsset.rawValue)
                
                return
            }
            
            strongSelf.progressBlock?(progress: progress)
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

            // TODO: What's the difference between this cancellation and checking the above cancellation? [AH]
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }

            // TODO: Do we need to check this? [AH]
            if let info = info, let inCloud = info[PHImageResultIsInCloudKey] as? Bool where inCloud == true
            {
                print("Video is in cloud")
            }

            if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                strongSelf.error = error.errorByAddingDomain(UploadErrorDomain.PHAsset.rawValue)
                
                return
            }
            
            guard let asset = asset else
            {
                strongSelf.error = NSError.phAssetNilAssetError()
                
                return
            }
            
            strongSelf.avAsset = asset            
        }        
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.progressBlock = nil

        if let requestID = self.requestID
        {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
            
            self.requestID = nil
        }
    }
}

//
//  DiskSpaceOperation.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
//  Copyright © 2015 Vimeo. All rights reserved.
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

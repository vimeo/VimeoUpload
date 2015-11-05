//
//  PHAssetCollectionHelper.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/3/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import Photos

typealias PHAssetHelperImageBlock = (image: UIImage?, inCloud: Bool?, error: NSError?) -> Void
typealias PHAssetHelperAssetBlock = (asset: AVAsset?, inCloud: Bool?, error: NSError?) -> Void

@available(iOS 8, *)
class PHAssetHelper
{
    static let ErrorDomain = "PHAssetHelperErrorDomain"
    
    private let imageManager: PHImageManager
    private var activeImageRequests: [String: PHImageRequestID] = [:]
    private var activeAssetRequests: [String: PHImageRequestID] = [:]

    init(imageManager: PHImageManager)
    {
        self.imageManager = imageManager
    }
    
    deinit
    {
        // Cancel any remaining active PHImageManager requests
        
        for requestID in self.activeImageRequests.values
        {
            self.imageManager.cancelImageRequest(requestID)
        }
        self.activeImageRequests.removeAll()
        
        for requestID in self.activeAssetRequests.values
        {
            self.imageManager.cancelImageRequest(requestID)
        }
        self.activeAssetRequests.removeAll()
    }

    // MARK: Public API
    
    func requestImage(phAsset: PHAsset, size: CGSize, completion: PHAssetHelperImageBlock)
    {
        self.cancelImageRequestForPHAsset(phAsset)
        
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true // We do not check for inCloud in resultHandler because we allow network access
        options.deliveryMode = .Opportunistic
        options.version = .Current
        options.resizeMode = .Fast
        
        let requestID = self.imageManager.requestImageForAsset(phAsset, targetSize: size, contentMode: .AspectFill, options: options, resultHandler: { [weak self] (image, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.cancelImageRequestForPHAsset(phAsset)
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            let inCloud = info?[PHImageResultIsInCloudKey] as? Bool
            let error = info?[PHImageErrorKey] as? NSError

            if let error = error
            {
                completion(image: nil, inCloud: inCloud, error: error)
            }
            else if let image = image
            {
                completion(image: image, inCloud: inCloud, error: nil)
            }
        })
        
        self.activeImageRequests[phAsset.localIdentifier] = requestID
    }
    
    func requestAsset(phAsset: PHAsset, networkAccessAllowed: Bool, progress: PHAssetVideoProgressHandler?, completion: PHAssetHelperAssetBlock)
    {
        self.cancelAssetRequestForPHAsset(phAsset)
        
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = networkAccessAllowed
        options.deliveryMode = .HighQualityFormat
        options.progressHandler = progress
        
        let requestID = self.imageManager.requestAVAssetForVideo(phAsset, options: options) { [weak self] (asset, audioMix, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.cancelAssetRequestForPHAsset(phAsset)

            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let _ = self else
                {
                    return
                }

                let inCloud = info?[PHImageResultIsInCloudKey] as? Bool
                let error = info?[PHImageErrorKey] as? NSError

                if let inCloud = inCloud where inCloud == true && networkAccessAllowed == false
                {
                    completion(asset: nil, inCloud: inCloud, error: nil)
                }
                else if let error = error
                {
                    completion(asset: nil, inCloud: inCloud, error: error)
                }
                else if let asset = asset
                {
                    completion(asset: asset, inCloud: inCloud, error: nil)
                }
                else
                {
                    assertionFailure("Execution should never reach this point")
                }
            })
        }
        
        self.activeAssetRequests[phAsset.localIdentifier] = requestID
    }
    
    func cancelRequestsForPHAsset(phAsset: PHAsset)
    {
        self.cancelImageRequestForPHAsset(phAsset)
        self.cancelAssetRequestForPHAsset(phAsset)
    }

    // MARK: Private API

    private func cancelImageRequestForPHAsset(phAsset: PHAsset)
    {
        if let requestID = self.activeImageRequests[phAsset.localIdentifier]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeImageRequests.removeValueForKey(phAsset.localIdentifier)
        }
    }
    
    private func cancelAssetRequestForPHAsset(phAsset: PHAsset)
    {
        if let requestID = self.activeAssetRequests[phAsset.localIdentifier]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeAssetRequests.removeValueForKey(phAsset.localIdentifier)
        }
    }
}
//
//  PHAssetCollectionHelper.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/3/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import Photos

typealias PHAssetHelperImageBlock = (image: UIImage?, error: NSError?) -> Void
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
        options.networkAccessAllowed = true
        options.deliveryMode = .HighQualityFormat
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
            
            if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                completion(image: nil, error: error)
                
                return
            }
            
            guard let image = image else
            {
                let error = NSError(domain: PHAssetHelper.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Fetched nil image"])
                completion(image: nil, error: error)
                
                return
            }
            
            completion(image: image, error: nil)
        })
        
        self.activeImageRequests[phAsset.localIdentifier] = requestID
    }
    
    func requestAsset(phAsset: PHAsset, networkAccessAllowed: Bool, completion: PHAssetHelperAssetBlock)
    {
        self.cancelAssetRequestForPHAsset(phAsset)
        
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = networkAccessAllowed
        options.deliveryMode = .HighQualityFormat
        
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

                if let info = info, let inCloud = info[PHImageResultIsInCloudKey] as? Bool where inCloud == true
                {
                    completion(asset: nil, inCloud: inCloud, error: nil)
                    
                    return
                }
                
                if let info = info, let error = info[PHImageErrorKey] as? NSError
                {
                    completion(asset: nil, inCloud: nil, error: error)
                    
                    return
                }
                
                guard let asset = asset else
                {
                    let error = NSError(domain: PHAssetHelper.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Fetched nil asset"])
                    completion(asset: nil, inCloud: false, error: error)
                    
                    return
                }

                completion(asset: asset, inCloud: false, error: nil)
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
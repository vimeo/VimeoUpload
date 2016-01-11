//
//  PHAssetHelper.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/3/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import Photos

@available(iOS 8, *)
@objc class PHAssetHelper: NSObject, CameraRollAssetHelper
{
    static let ErrorDomain = "PHAssetHelperErrorDomain"
    
    private let imageManager = PHImageManager.defaultManager()
    private var activeImageRequests: [String: PHImageRequestID] = [:]
    private var activeAssetRequests: [String: PHImageRequestID] = [:]

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

    // MARK: CameraRollAssetHelper
    
    func requestImage(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    {
        let phAsset = (cameraRollAsset as! VIMPHAsset).phAsset
        let size = cell.bounds.size
        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeMake(scale * size.width, scale * size.height)
     
        self.cancelImageRequest(cameraRollAsset: cameraRollAsset)

        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true // We do not check for inCloud in resultHandler because we allow network access
        options.deliveryMode = .Opportunistic
        options.version = .Current
        options.resizeMode = .Fast
        
        let requestID = self.imageManager.requestImageForAsset(phAsset, targetSize: scaledSize, contentMode: .AspectFill, options: options, resultHandler: { [weak self] (image, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            // TODO: determine if we can use this here and below Phimageresultrequestidkey
            strongSelf.cancelImageRequest(cameraRollAsset: cameraRollAsset)
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            // Cache values for later use in didSelectItem
            cameraRollAsset.inCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
            cameraRollAsset.error = info?[PHImageErrorKey] as? NSError
            
            if cameraRollAsset.inCloud == true
            {
                cell.setInCloud()
            }
            
            if let image = image
            {
                cell.setImage(image)
            }
            else if let _ = cameraRollAsset.error
            {
                // Do nothing, placeholder image that's embedded in the cell's nib will remain visible
            }
        })
        
        self.activeImageRequests[phAsset.localIdentifier] = requestID
    }
    
    func requestAsset(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    {
        let phAsset = (cameraRollAsset as! VIMPHAsset).phAsset

        cell.setDuration(seconds: phAsset.duration)

        self.cancelAssetRequest(cameraRollAsset: cameraRollAsset)
        
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = false
        options.deliveryMode = .HighQualityFormat
        
        let requestID = self.imageManager.requestAVAssetForVideo(phAsset, options: options) { [weak self] (asset, audioMix, info) -> Void in
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }

                strongSelf.cancelAssetRequest(cameraRollAsset: cameraRollAsset)

                // Cache the asset and inCloud values for later use in didSelectItem
                cameraRollAsset.avAsset = asset
                cameraRollAsset.inCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                cameraRollAsset.error = info?[PHImageErrorKey] as? NSError

                if cameraRollAsset.inCloud == true
                {
                    cell.setInCloud()
                }

                if let asset = asset
                {
                    asset.approximateFileSize({ (value) -> Void in
                        cell.setFileSize(bytes: value)
                    })
                }
                else if let _ = cameraRollAsset.error
                {
                     // Set empty strings when asset is not available
                    cell.setFileSize(bytes: 0)
                    cell.setDuration(seconds: 0)
                }
            })
        }
        
        self.activeAssetRequests[phAsset.localIdentifier] = requestID
    }
    
    func cancelRequests(cameraRollAsset: CameraRollAsset)
    {
        self.cancelImageRequest(cameraRollAsset: cameraRollAsset)
        self.cancelAssetRequest(cameraRollAsset: cameraRollAsset)
    }

    // MARK: Private API

    private func cancelImageRequest(cameraRollAsset cameraRollAsset: CameraRollAsset)
    {
        let phAsset = (cameraRollAsset as! VIMPHAsset).phAsset
        
        if let requestID = self.activeImageRequests[phAsset.localIdentifier]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeImageRequests.removeValueForKey(phAsset.localIdentifier)
        }
    }
    
    private func cancelAssetRequest(cameraRollAsset cameraRollAsset: CameraRollAsset)
    {
        let phAsset = (cameraRollAsset as! VIMPHAsset).phAsset
        
        if let requestID = self.activeAssetRequests[phAsset.localIdentifier]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeAssetRequests.removeValueForKey(phAsset.localIdentifier)
        }
    }
}
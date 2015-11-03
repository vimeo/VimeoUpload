//
//  PHAssetCollectionHelper.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/3/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import Photos

@available(iOS 8, *)
class PHAssetHelper
{
    private let imageManager: PHImageManager
    
    private var activeImageRequests: [NSIndexPath: PHImageRequestID] = [:]
    private var activeAssetRequests: [NSIndexPath: PHImageRequestID] = [:]

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
    
    func requestImage(vimeoPHAsset: VimeoPHAsset, cell: CameraRollCell, indexPath: NSIndexPath)
    {
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
        options.deliveryMode = .HighQualityFormat
        options.resizeMode = .Fast
        
        let scale = UIScreen.mainScreen().scale
        let size = CGSizeMake(scale * cell.imageView.bounds.size.width, scale * cell.imageView.bounds.size.height)
        
        let requestID = self.imageManager.requestImageForAsset(vimeoPHAsset.phAsset, targetSize: size, contentMode: .AspectFill, options: options, resultHandler: { [weak self] (image, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.cancelImageRequestForCellAtIndexPath(indexPath)
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                print("image cancelled")
                
                return
            }
            
            if let info = info, let _ = info[PHImageErrorKey] as? NSError
            {
                print("image error")
                
                cell.setError("Error fetching image")
                
                return
            }
            
            guard let image = image else
            {
                print("image nil")
                
                cell.setError("Fetched nil image")
                
                return
            }
            
            cell.setImage(image)
            })
        
        self.activeImageRequests[indexPath] = requestID
    }
    
    func requestAsset(vimeoPHAsset: VimeoPHAsset, cell: CameraRollCell, indexPath: NSIndexPath)
    {
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = false // Disallow network access in order to determine asset location (iCloud or device)
        options.deliveryMode = .HighQualityFormat
        
        let requestID = self.imageManager.requestAVAssetForVideo(vimeoPHAsset.phAsset, options: options) { (asset, audioMix, info) -> Void in
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                print("asset cancelled")
                
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                // Cache the asset and inCloud values for later use in didSelectItem
                
                if let info = info, let inCloud = info[PHImageResultIsInCloudKey] as? Bool where inCloud == true
                {
                    print("icloud")
                    
                    vimeoPHAsset.inCloud = inCloud
                    
                    cell.setError("iCloud asset")
                    
                    return
                }
                
                if let info = info, let _ = info[PHImageErrorKey] as? NSError
                {
                    print("asset error")
                    
                    cell.setError("Error fetching asset")
                    
                    return
                }
                
                vimeoPHAsset.inCloud = false // Update this specifically after checking for an error
                
                guard let asset = asset else
                {
                    print("asset nil")
                    
                    cell.setError("asset nil")
                    
                    return
                }
                
                vimeoPHAsset.avAsset = asset
                
                self?.configureCellForAsset(cell, asset: asset)
                
            })
        }
        
        self.activeAssetRequests[indexPath] = requestID
    }
    
    func cancelRequestsForCellAtIndexPath(indexPath: NSIndexPath)
    {
        self.cancelImageRequestForCellAtIndexPath(indexPath)
        self.cancelAssetRequestForCellAtIndexPath(indexPath)
    }

    func configureCellForAsset(cell: CameraRollCell, asset: AVAsset)
    {
        let seconds = CMTimeGetSeconds(asset.duration)
        cell.setDuration(seconds)
        
        let megabytes = asset.approximateFileSizeInMegabytes()
        cell.setFileSize(megabytes)
    }

    // MARK: Private API

    private func cancelImageRequestForCellAtIndexPath(indexPath: NSIndexPath)
    {
        if let requestID = self.activeImageRequests[indexPath]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeImageRequests.removeValueForKey(indexPath)
        }
    }
    
    private func cancelAssetRequestForCellAtIndexPath(indexPath: NSIndexPath)
    {
        if let requestID = self.activeImageRequests[indexPath]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeAssetRequests.removeValueForKey(indexPath)
        }
    }
}
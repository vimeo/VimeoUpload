//
//  PHAssetHelper.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/3/15.
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

@objc class PHAssetHelper: NSObject
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
    
    func requestImage(cell cell: CameraRollAssetCell, cameraRollAsset: VIMPHAsset)
    {
        let phAsset = cameraRollAsset.phAsset
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
            
            // TODO: Determine if we can use this here and below Phimageresultrequestidkey [AH] Jan 2016
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
    
    func requestAsset(cell cell: CameraRollAssetCell, cameraRollAsset: VIMPHAsset)
    {
        let phAsset = cameraRollAsset.phAsset

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
    
    func cancelRequests(cameraRollAsset: VIMPHAsset)
    {
        self.cancelImageRequest(cameraRollAsset: cameraRollAsset)
        self.cancelAssetRequest(cameraRollAsset: cameraRollAsset)
    }

    // MARK: Private API

    private func cancelImageRequest(cameraRollAsset cameraRollAsset: VIMPHAsset)
    {
        let phAsset = cameraRollAsset.phAsset
        
        if let requestID = self.activeImageRequests[phAsset.localIdentifier]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeImageRequests.removeValueForKey(phAsset.localIdentifier)
        }
    }
    
    private func cancelAssetRequest(cameraRollAsset cameraRollAsset: VIMPHAsset)
    {
        let phAsset = cameraRollAsset.phAsset
        
        if let requestID = self.activeAssetRequests[phAsset.localIdentifier]
        {
            self.imageManager.cancelImageRequest(requestID)
            self.activeAssetRequests.removeValueForKey(phAsset.localIdentifier)
        }
    }
}
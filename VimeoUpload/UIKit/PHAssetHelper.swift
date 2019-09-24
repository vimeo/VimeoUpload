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

@objc public class PHAssetHelper: NSObject {
    static let ErrorDomain = "PHAssetHelperErrorDomain"

    private var activeImageRequests: [String: PHImageRequestID] = [:]
    private var activeAssetRequests: [String: PHImageRequestID] = [:]

    deinit {
        // Cancel any remaining active PHImageManager requests

        for requestID in self.activeImageRequests.values {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        self.activeImageRequests.removeAll()

        for requestID in self.activeAssetRequests.values {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        self.activeAssetRequests.removeAll()
    }

    @objc public func requestImage(cell: CameraRollAssetCell, cameraRollAsset: VIMPHAsset) {
        let phAsset = cameraRollAsset.phAsset
        let identifier = phAsset.localIdentifier
        let size = cell.bounds.size
        let scale = UIScreen.main.scale
        let scaledSize = CGSize(width: scale * size.width, height: scale * size.height)

        cell.assetIdentifier = identifier

        self.cancelImageRequest(cameraRollAsset: cameraRollAsset)

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true // We do not check for inCloud in resultHandler because we allow network access
        options.deliveryMode = .opportunistic
        options.version = .current
        options.resizeMode = .fast

        let requestID = PHImageManager.default().requestImage(
            for: phAsset,
            targetSize: scaledSize,
            contentMode: .aspectFill,
            options: options,
            resultHandler: { [weak self] image, info in
                guard let self = self else { return }

                // TODO: Determine if we can use this here and below Phimageresultrequestidkey [AH] Jan 2016
                self.cancelImageRequest(cameraRollAsset: cameraRollAsset)

                guard cell.assetIdentifier == identifier else { return }

                if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool, cancelled == true {
                    return
                }

                // Cache values for later use in didSelectItem
                cameraRollAsset.inCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                cameraRollAsset.error = info?[PHImageErrorKey] as? NSError

                if cameraRollAsset.inCloud == true {
                    cell.setInCloud()
                }

                if let image = image {
                    cell.set(image: image)
                } else if let _ = cameraRollAsset.error {
                    // Do nothing, placeholder image that's embedded in the cell's nib will remain visible
                }
            }
        )

        self.activeImageRequests[phAsset.localIdentifier] = requestID
    }

    @objc public func requestAsset(cell: CameraRollAssetCell, cameraRollAsset: VIMPHAsset) {
        let phAsset = cameraRollAsset.phAsset
        let identifier = phAsset.localIdentifier

        cell.setDuration(seconds: phAsset.duration)
        cell.assetIdentifier = identifier

        self.cancelAssetRequest(cameraRollAsset: cameraRollAsset)

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat

        let requestID = PHImageManager.default().requestAVAsset(
            forVideo: phAsset,
            options: options,
            resultHandler:  { [weak self] asset, audioMix, info in
                if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool, cancelled == true {
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    self.cancelAssetRequest(cameraRollAsset: cameraRollAsset)

                    guard cell.assetIdentifier == identifier else { return }

                    // Cache the asset and inCloud values for later use in didSelectItem
                    cameraRollAsset.avAsset = asset
                    cameraRollAsset.inCloud = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                    cameraRollAsset.error = info?[PHImageErrorKey] as? NSError

                    if let asset = asset {
                        asset.approximateFileSize { (value) -> Void in
                            cell.setFileSize(bytes: value)
                        }
                    } else {
                        // If we don't have the asset locally, it must be in the cloud.
                        cell.setInCloud()
                    }
                }
            }
        )

        self.activeAssetRequests[phAsset.localIdentifier] = requestID
    }

    @objc public func cancelRequests(with cameraRollAsset: VIMPHAsset) {
        self.cancelImageRequest(cameraRollAsset: cameraRollAsset)
        self.cancelAssetRequest(cameraRollAsset: cameraRollAsset)
    }

    // MARK: Private API

    private func cancelImageRequest(cameraRollAsset: VIMPHAsset) {
        let phAsset = cameraRollAsset.phAsset

        if let requestID = self.activeImageRequests[phAsset.localIdentifier] {
            PHImageManager.default().cancelImageRequest(requestID)
            self.activeImageRequests.removeValue(forKey: phAsset.localIdentifier)
        }
    }

    private func cancelAssetRequest(cameraRollAsset: VIMPHAsset) {
        let phAsset = cameraRollAsset.phAsset

        if let requestID = self.activeAssetRequests[phAsset.localIdentifier] {
            PHImageManager.default().cancelImageRequest(requestID)
            self.activeAssetRequests.removeValue(forKey: phAsset.localIdentifier)
        }
    }
}

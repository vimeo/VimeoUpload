//
//  PHAssetCell.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/1/15.
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

import UIKit
import Photos

@available(iOS 8, *)
class PHAssetCell: UICollectionViewCell
{
    static let CellIdentifier = "PHAssetCellIdentifier"
    static let NibName = "PHAssetCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var durationlabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var imageRequestID: PHImageRequestID?
    private var assetRequestID: PHImageRequestID?

    var phAsset: PHAsset?
    {
        didSet
        {
            if let phAsset = self.phAsset
            {
                self.setupImageView(phAsset)
                self.setupTextLabels(phAsset)
            }
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    
        self.fileSizeLabel.text = ""
        self.durationlabel.text = ""
        self.errorLabel.text = ""
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
        
        self.phAsset = nil
        
        if let requestID = self.imageRequestID
        {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
        }

        if let requestID = self.assetRequestID
        {
            PHImageManager.defaultManager().cancelImageRequest(requestID)
        }

        self.imageRequestID = nil
        self.assetRequestID = nil
        
        self.imageView.image = nil
        self.fileSizeLabel.text = ""
        self.durationlabel.text = ""
        self.errorLabel.text = ""
    }
    
    // MARK: Setup
    
    // TODO: move both of these methods into NSOperation subclasses [AH] 11/1/2015
    
    private func setupImageView(phAsset: PHAsset)
    {
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
        options.deliveryMode = .HighQualityFormat
        options.resizeMode = .Fast

        self.imageRequestID = PHImageManager.defaultManager().requestImageForAsset(phAsset, targetSize: self.imageView.bounds.size, contentMode: .AspectFill, options: options, resultHandler: { [weak self] (image, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            guard phAsset == strongSelf.phAsset else
            {
                return
            }
            
            strongSelf.imageRequestID = nil
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                print("Error fetching image for PHAsset: \(error)")
                
                strongSelf.errorLabel.text = "Error fetching image"
                
                return
            }
            
            guard let image = image else
            {
                print("Fetched nil image for PHAsset")
                
                strongSelf.errorLabel.text = "Fetched nil image"

                return
            }

            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                self?.imageView.image = image
            })
        })
    }
    
    private func setupTextLabels(phAsset: PHAsset)
    {
        let options = PHVideoRequestOptions()
        options.networkAccessAllowed = false
        options.deliveryMode = .FastFormat // We just want info about the filesize and duration

        self.assetRequestID = PHImageManager.defaultManager().requestAVAssetForVideo(phAsset, options: options) { [weak self] (asset, audioMix, info) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            guard phAsset == strongSelf.phAsset else
            {
                return
            }

            strongSelf.assetRequestID = nil
            
            if let info = info, let cancelled = info[PHImageCancelledKey] as? Bool where cancelled == true
            {
                return
            }
            
            if let info = info, let inCloud = info[PHImageResultIsInCloudKey] as? Bool where inCloud == true
            {
                print("iCloud asset")
                
                strongSelf.errorLabel.text = "iCloud asset"

                return
            }
            
            if let info = info, let error = info[PHImageErrorKey] as? NSError
            {
                print("Error fetching AVAsset for PHAsset: \(error)")

                strongSelf.errorLabel.text = "Error fetching asset"

                return
            }
            
            guard let asset = asset else
            {
                print("Fetched nil AVAsset for PHAsset")
                
                strongSelf.errorLabel.text = "Fetched nil asset"

                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                self?.durationlabel?.text = String.stringFromDurationInSeconds(CMTimeGetSeconds(asset.duration))
            })
        }
    }
}

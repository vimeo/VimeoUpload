//
//  ALAssetHelper.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 12/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AssetsLibrary
import AVFoundation

@objc class ALAssetHelper: NSObject, CameraRollAssetHelper
{
    func requestImage(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    {
        let alAsset = (cameraRollAsset as! VIMALAsset).alAsset

        cameraRollAsset.inCloud = false

        let imageRef = alAsset.thumbnail().takeUnretainedValue()
        let image = UIImage(CGImage: imageRef)
        cell.setImage(image)
    }
    
    func requestAsset(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    {
        let alAsset = (cameraRollAsset as! VIMALAsset).alAsset
        
        if let url = alAsset.defaultRepresentation().url()
        {
            let asset = AVURLAsset(URL: url)
            
            cameraRollAsset.avAsset = asset
            cameraRollAsset.inCloud = false
            
            let seconds = CMTimeGetSeconds(asset.duration)
            cell.setDuration(seconds: seconds)

            asset.approximateFileSize({ (value) -> Void in
                cell.setFileSize(bytes: value)
            })
        }
        else
        {
            cell.setFileSize(bytes: 0)
            cell.setDuration(seconds: 0)
        }
    }
}
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
        let alAsset = cameraRollAsset as! ALAsset

        cameraRollAsset.inCloud = false

        // TODO: cache info
        // TODO: configure cell
    }
    
    func requestAsset(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    {
        let alAsset = cameraRollAsset as! ALAsset
        
        if let url = alAsset.defaultRepresentation().url()
        {
            cameraRollAsset.avAsset = AVURLAsset(URL: url)
            cameraRollAsset.inCloud = false
            
            // TODO: configure cell
        }
    }
}
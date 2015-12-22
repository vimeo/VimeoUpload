//
//  VIMALAsset.swift
//  Smokescreen
//
//  Created by Hanssen, Alfie on 12/22/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import AssetsLibrary
import AVFoundation

@objc class VIMALAsset: NSObject, CameraRollAssetProtocol
{
    let alAsset: ALAsset

    init(alAsset: ALAsset)
    {
        self.alAsset = alAsset
    }

    var identifier: String
    {
        get
        {
            return self.alAsset.defaultRepresentation().url().absoluteString
        }
    }
    
    var inCloud: Bool = false
    var avAsset: AVAsset?
    var error: NSError?
}

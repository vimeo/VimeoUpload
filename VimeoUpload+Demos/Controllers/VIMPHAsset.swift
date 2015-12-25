//
//  VIMPHAsset.swift
//  Smokescreen
//
//  Created by Hanssen, Alfie on 12/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Photos
import AVFoundation

@available(iOS 8.0, *)
@objc class VIMPHAsset: NSObject, CameraRollAsset
{
    let phAsset: PHAsset
    
    init(phAsset: PHAsset)
    {
        self.phAsset = phAsset
    }

    var identifier: String
    {
        get
        {
            return self.phAsset.localIdentifier
        }
    }
    
    var inCloud: Bool = false
    var avAsset: AVAsset?
    var error: NSError?
}

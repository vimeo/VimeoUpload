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
class VIMPHAsset: PHAsset, CameraRollAssetProtocol
{
    var identifier: String
    {
        get
        {
            return self.localIdentifier
        }
    }
    
    var inCloud: Bool = false
    var avAsset: AVAsset?
    var error: NSError?
}

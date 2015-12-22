//
//  VIMALAsset.swift
//  Smokescreen
//
//  Created by Hanssen, Alfie on 12/22/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit
import AssetsLibrary

class VIMALAsset: ALAsset, CameraRollAssetProtocol
{
    var identifier: String
        {
        get
        {
            return self.defaultRepresentation().url().absoluteString
        }
    }
    
    var inCloud: Bool = false
    var avAsset: AVAsset?
    var error: NSError?
}

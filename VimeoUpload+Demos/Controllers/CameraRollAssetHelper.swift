//
//  CameraRollAssetHelper.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 12/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

@objc protocol CameraRollAssetHelper
{
    func requestImage(cell cell: CameraRollCell, cameraRollAsset: CameraRollAsset)
    func requestAsset(cell cell: CameraRollCell, cameraRollAsset: CameraRollAsset)
    
    optional func cancelRequests(cameraRollAsset: CameraRollAsset)
}
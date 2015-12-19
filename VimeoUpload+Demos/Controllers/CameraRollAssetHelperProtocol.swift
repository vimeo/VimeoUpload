//
//  CameraRollAssetHelperProtocol.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 12/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

@objc protocol CameraRollAssetHelperProtocol
{
    func requestImage(cell cell: CameraRollCell, cameraRollAsset: CameraRollAssetProtocol)
    func requestAsset(cell cell: CameraRollCell, cameraRollAsset: CameraRollAssetProtocol)
    
    optional func cancelRequests(cameraRollAsset: CameraRollAssetProtocol)
}
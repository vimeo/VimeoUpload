//
//  CameraRollAssetHelper.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 12/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

@objc protocol CameraRollAssetHelper
{
    func requestImage(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    func requestAsset(cell cell: CameraRollAssetCell, cameraRollAsset: CameraRollAsset)
    
    optional func cancelRequests(cameraRollAsset: CameraRollAsset)
}

@objc protocol CameraRollAssetCell
{
    var bounds: CGRect { get }
    func setImage(image: UIImage)
    func setDuration(seconds seconds: Float64)
    func setFileSize(bytes bytes: Float64)
    func setInCloud()
}

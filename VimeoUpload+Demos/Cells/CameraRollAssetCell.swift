//
//  CameraRollAssetCell.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 2/5/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

@objc protocol CameraRollAssetCell
{
    var bounds: CGRect { get }
    func setImage(image: UIImage)
    func setDuration(seconds seconds: Float64)
    func setFileSize(bytes bytes: Float64)
    func setInCloud()
}

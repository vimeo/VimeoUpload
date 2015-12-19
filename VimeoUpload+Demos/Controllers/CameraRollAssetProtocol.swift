//
//  CameraRollAssetProtocol.swift
//  Smokescreen
//
//  Created by Hanssen, Alfie on 12/17/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

@objc protocol CameraRollAssetProtocol
{
    var identifier: String { get }
    var inCloud: Bool { get set }
    var avAsset: AVAsset? { get set }
    var error: NSError? { get set }
}
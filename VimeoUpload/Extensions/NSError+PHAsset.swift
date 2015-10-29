//
//  NSError+PHAsset.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSError
{
    static func phAssetNilAssetError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.PHAsset.rawValue, code: UploadErrorCode.NilPHAsset.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.NilPHAsset.rawValue]).errorByAddingDomain(UploadErrorDomain.PHAsset.rawValue)
    }
}
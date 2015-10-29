//
//  NSError+VideoSettings.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSError
{
    static func nilVideoSettingsUriError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.VideoSettings.rawValue, code: UploadErrorCode.NilVideoUri.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.NilVideoUri.rawValue]).errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
    }

    static func nilVideoSettingsError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.VideoSettings.rawValue, code: UploadErrorCode.EmptyVideoSettings.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.EmptyVideoSettings.rawValue]).errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
    }
}
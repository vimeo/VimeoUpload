//
//  NSError+Export.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSError
{
    static func assetNotExportableError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Export.rawValue, code: UploadErrorCode.AssetNotExportable.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.AssetNotExportable.rawValue]).errorByAddingDomain(UploadErrorDomain.Export.rawValue)
    }
    
    static func assetHasProtectedContentError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Export.rawValue, code: UploadErrorCode.AssetHasProtectedContent.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.AssetHasProtectedContent.rawValue]).errorByAddingDomain(UploadErrorDomain.Export.rawValue)
    }
    
    static func invalidExportSessionError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Export.rawValue, code: UploadErrorCode.InvalidExportSession.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidExportSession.rawValue]).errorByAddingDomain(UploadErrorDomain.Export.rawValue)
    }
    
    static func unableToCalculateAvailableDiskSpaceError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Export.rawValue, code: UploadErrorCode.UnableToCalculateAvailableDiskSpace.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.UnableToCalculateAvailableDiskSpace.rawValue]).errorByAddingDomain(UploadErrorDomain.Export.rawValue)
    }
    
    static func noDiskSpaceAvailableError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Export.rawValue, code: UploadErrorCode.NoDiskSpaceAvailable.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.NoDiskSpaceAvailable.rawValue]).errorByAddingDomain(UploadErrorDomain.Export.rawValue)
    }
}
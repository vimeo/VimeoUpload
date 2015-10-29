//
//  NSError+Create.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSError
{
    static func createFileLengthUnavailableError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Create.rawValue, code: UploadErrorCode.FileLengthUnavailable.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.FileLengthUnavailable.rawValue]).errorByAddingDomain(UploadErrorDomain.Create.rawValue)
    }
    
    static func nilCreateDownloadUrlError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Create.rawValue, code: UploadErrorCode.NilCreateDownloadUrl.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.NilCreateDownloadUrl.rawValue]).errorByAddingDomain(UploadErrorDomain.Create.rawValue)
    }
    
    static func nilCreateDataError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Create.rawValue, code: UploadErrorCode.NilCreateResponseData.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.NilCreateResponseData.rawValue]).errorByAddingDomain(UploadErrorDomain.Create.rawValue)
    }
    
    static func invalidCreateResponseError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Create.rawValue, code: UploadErrorCode.InvalidCreateResponse.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidCreateResponse.rawValue]).errorByAddingDomain(UploadErrorDomain.Create.rawValue)
    }
    
    static func createFileSizeNotAvailableError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Create.rawValue, code: UploadErrorCode.CreateFileSizeNotAvailable.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.CreateFileSizeNotAvailable.rawValue]).errorByAddingDomain(UploadErrorDomain.Create.rawValue)
    }
}
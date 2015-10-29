//
//  NSError+Descriptor.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSError
{
    static func invalidDescriptorError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Descriptor.rawValue, code: UploadErrorCode.InvalidDescriptorNoTasks.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidDescriptorNoTasks.rawValue])
    }

    static func createResponseWithoutUploadUriError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Descriptor.rawValue, code: UploadErrorCode.InvalidDescriptorNoTasks.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidDescriptorNoTasks.rawValue])
    }

    static func createResponseWithoutActivateUriError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Descriptor.rawValue, code: UploadErrorCode.InvalidDescriptorNoTasks.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidDescriptorNoTasks.rawValue])
    }

    static func activateResponseWithoutVideoUriError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Descriptor.rawValue, code: UploadErrorCode.InvalidDescriptorNoTasks.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidDescriptorNoTasks.rawValue])
    }
}
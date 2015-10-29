//
//  NSError+Activate.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSError
{
    static func invalidActivateResponseError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Activate.rawValue, code: UploadErrorCode.InvalidActivateResponse.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.InvalidActivateResponse.rawValue]).errorByAddingDomain(UploadErrorDomain.Activate.rawValue)
    }
}
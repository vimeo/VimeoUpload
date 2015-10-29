//
//  NSError+Create.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/25/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
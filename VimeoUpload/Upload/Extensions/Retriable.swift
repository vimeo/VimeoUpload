//
//  Retriable.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 12/7/18.
//  Copyright © 2018 Vimeo. All rights reserved.
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

/// Classes conforming to `Retriable` can determine if they should
/// retry uploading/downloading based on the server response.
public protocol Retriable
{
    /// Determines if an upload/download should retry based on an HTTP
    /// response.
    ///
    /// - Parameter urlResponse: An HTTP response.
    /// - Returns: `true` if an upload/download should retry, and `false`
    /// otherwise.
    func shouldRetry(urlResponse: URLResponse?) -> Bool
}

public extension Retriable where Self: Descriptor
{
    func shouldRetry(urlResponse: URLResponse?) -> Bool
    {
        return false
    }
}

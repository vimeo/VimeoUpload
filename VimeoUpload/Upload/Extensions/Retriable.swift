//
//  Retriable.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 12/7/18.
//  Copyright © 2018 Vimeo. All rights reserved.
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

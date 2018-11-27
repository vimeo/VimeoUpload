//
//  UploadStrategy.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 11/13/18.
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
import VimeoNetworking

public enum UploadLinkError: Error
{
    case noUploadLink
}

/// An abstract class that declares an interface to assist
/// `UploadDescriptor` in getting an upload task and an upload link.
public protocol UploadStrategy
{
    /// Creates an appropriate upload task for the upload descriptor.
    ///
    /// - Parameters:
    ///   - sessionManager: An upload session manager.
    ///   - fileUrl: An URL to a video file.
    ///   - uploadLink: A destination URL to send the video file to.
    /// - Returns: An upload task.
    /// - Throws: An `NSError` that describes why an upload task cannot be
    /// created.
    func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    
    /// Returns an appropriate upload link.
    ///
    /// - Parameter video: A video object returned by `CreateVideoOperation`.
    /// - Returns: An upload link if it exists in the video object.
    /// - Throws: One of the values of `UploadLinkError` if there is a problem
    /// with the upload link.
    func uploadLink(from video: VIMVideo) throws -> String
}

/// An upload strategy that supports the streaming upload approach.
public struct StreamingUploadStrategy: UploadStrategy
{
    public func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    {
        let task = try sessionManager.uploadVideoTask(source: fileUrl, destination: uploadLink, completionHandler: nil)
        
        return task
    }
    
    public func uploadLink(from video: VIMVideo) throws -> String
    {
        guard let uploadLink = video.upload?.uploadLink else
        {
            throw UploadLinkError.noUploadLink
        }
        
        return uploadLink
    }
}

//
//  VimeoRequestSerializer+Upload.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/21/15.
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
import AVFoundation

extension VimeoRequestSerializer
{    
    func meRequest() throws -> NSMutableURLRequest
    {
        let url = NSURL(string: "/me", relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        let request = self.requestWithMethod("GET", URLString: url.absoluteString!, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Me.rawValue)
        }
        
        return request
    }

    func myVideosRequest() throws -> NSMutableURLRequest
    {
        let url = NSURL(string: "/me/videos", relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        let request = self.requestWithMethod("GET", URLString: url.absoluteString!, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.MyVideos.rawValue)
        }
        
        return request
    }

    func createVideoRequestWithUrl(url: NSURL) throws -> NSMutableURLRequest
    {
        let parameters = try self.createVideoRequestBaseParameters(url: url)
        
        let url = NSURL(string: "/me/videos", relativeToURL: VimeoBaseURLString)!

        return try self.createVideoRequestWithUrl(url, parameters: parameters)
    }

    func createVideoRequestWithUrl(url: NSURL, parameters: [String: AnyObject]) throws -> NSMutableURLRequest
    {
        var error: NSError?
        let request = self.requestWithMethod("POST", URLString: url.absoluteString!, parameters: parameters, error: &error)

        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
        
        return request
    }

    func createVideoRequestBaseParameters(url url: NSURL) throws -> [String: AnyObject]
    {
        let asset = AVURLAsset(URL: url)
        
        let fileSize: NSNumber
        do
        {
            fileSize = try asset.fileSize()
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
        
        return ["type": "streaming", "size": fileSize]
    }

    func uploadVideoRequestWithSource(source: NSURL, destination: String) throws -> NSMutableURLRequest
    {
        guard let path = source.path where NSFileManager.defaultManager().fileExistsAtPath(path) else
        {
            throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to construct upload request but the source file does not exist."])
        }
        
        var error: NSError?
        let request = self.requestWithMethod("PUT", URLString: destination, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
        
        let asset = AVURLAsset(URL: source)
        
        let fileSize: NSNumber
        do
        {
            fileSize = try asset.fileSize()
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
        
        request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        
        // For resumed uploads on a single upload ticket we must include this header per @naren (undocumented) [AH] 12/25/2015
        request.setValue("bytes 0-\(fileSize)/\(fileSize)", forHTTPHeaderField: "Content-Range")
        
        return request
    }
    
    func activateVideoRequestWithUri(uri: String) throws -> NSMutableURLRequest
    {
        let url = NSURL(string: uri, relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        let request = self.requestWithMethod("DELETE", URLString: url.absoluteString!, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Activate.rawValue)
        }
        
        return request
    }

    func videoSettingsRequestWithUri(videoUri: String, videoSettings: VideoSettings) throws -> NSMutableURLRequest
    {
        guard videoUri.characters.count > 0 else 
        {
            throw NSError(domain: UploadErrorDomain.VideoSettings.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "videoUri has length of 0."])
        }
        
        let url = NSURL(string: videoUri, relativeToURL: VimeoBaseURLString)!
        var error: NSError?

        let parameters = videoSettings.parameterDictionary()
        if parameters.count == 0
        {
            throw NSError(domain: UploadErrorDomain.VideoSettings.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Parameters dictionary is empty."])
        }
        
        let request = self.requestWithMethod("PATCH", URLString: url.absoluteString!, parameters: parameters, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
        }
        
        return request
    }
    
    func deleteVideoRequestWithUri(videoUri: String) throws -> NSMutableURLRequest
    {
        guard videoUri.characters.count > 0 else
        {
            throw NSError(domain: UploadErrorDomain.Delete.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "videoUri has length of 0."])
        }
        
        let url = NSURL(string: videoUri, relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        let request = self.requestWithMethod("DELETE", URLString: url.absoluteString!, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Delete.rawValue)
        }
        
        return request
    }

    func videoRequestWithUri(videoUri: String) throws -> NSMutableURLRequest
    {
        guard videoUri.characters.count > 0 else
        {
            throw NSError(domain: UploadErrorDomain.Video.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "videoUri has length of 0."])
        }
        
        let url = NSURL(string: videoUri, relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        let request = self.requestWithMethod("GET", URLString: url.absoluteString!, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Video.rawValue)
        }
        
        return request
    }
}

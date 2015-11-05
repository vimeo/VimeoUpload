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
        
        let request = self.requestWithMethod("GET", URLString: url.absoluteString, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain("MeErrorDomain")
        }
        
        return request
    }

    func createVideoRequestWithUrl(url: NSURL) throws -> NSMutableURLRequest
    {
        let asset = AVURLAsset(URL: url)
        
        var fileLength: NSNumber?
        do
        {
            fileLength = try asset.fileSize()
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
        
        guard let aFileLength = fileLength else
        {
            throw NSError.createFileLengthUnavailableError()
        }
        
        let url = NSURL(string: "/me/videos", relativeToURL: VimeoBaseURLString)!
        let parameters = ["type": "streaming", "size": aFileLength]
        var error: NSError?
        
        let request = self.requestWithMethod("POST", URLString: url.absoluteString, parameters: parameters, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
        
        return request
    }
    
    func uploadVideoRequestWithSource(source: NSURL, destination: String) throws -> NSMutableURLRequest
    {
        guard let path = source.path where NSFileManager.defaultManager().fileExistsAtPath(path) else
        {
            throw NSError.sourceFileDoesNotExistError()
        }
        
        var error: NSError?
        let request = self.requestWithMethod("PUT", URLString: destination, parameters: nil, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
        
        let asset = AVURLAsset(URL: source)
        
        var fileLength: NSNumber?
        do
        {
            fileLength = try asset.fileSize()
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
        
        guard let aFileLength = fileLength else
        {
            throw NSError.uploadFileLengthNotAvailable()
        }
        
        request.setValue("\(aFileLength)", forHTTPHeaderField: "Content-Length")
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    func activateVideoRequestWithUri(uri: String) throws -> NSMutableURLRequest
    {
        let url = NSURL(string: uri, relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        let request = self.requestWithMethod("DELETE", URLString: url.absoluteString, parameters: nil, error: &error)
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
            throw NSError.nilVideoSettingsUriError()
        }
        
        let url = NSURL(string: videoUri, relativeToURL: VimeoBaseURLString)!
        var error: NSError?
        
        var parameters: [String: AnyObject] = [:]
        if let title = videoSettings.title where title.characters.count > 0
        {
            parameters["name"] = title
        }

        if let description = videoSettings.desc where description.characters.count > 0
        {
            parameters["description"] = description
        }

        if videoSettings.privacy.characters.count > 0
        {
            parameters["privacy"] = ["view": videoSettings.privacy]
        }

        if parameters.count == 0
        {
            throw NSError.nilVideoSettingsError()
        }
        
        let request = self.requestWithMethod("PATCH", URLString: url.absoluteString, parameters: parameters, error: &error)
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
        }
        
        return request
    }
}
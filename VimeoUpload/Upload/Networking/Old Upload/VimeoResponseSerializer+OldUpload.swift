//
//  VimeoResponseSerializer+Upload.swift
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
import VimeoNetworking

extension VimeoResponseSerializer
{
    private static let LocationKey = "Location"
    
    func process(meResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMUser
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Me.rawValue)
        }
        
        do
        {
            return try self.user(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Me.rawValue)
        }
    }

    func process(myVideosResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> [VIMVideo]
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.MyVideos.rawValue)
        }
        
        do
        {
            return try self.videos(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.MyVideos.rawValue)
        }
    }

    func process(createVideoResponse response: URLResponse?, url: NSURL?, error: NSError?) throws -> VIMUploadTicket
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Create.rawValue)
        }

        return try self.process(createVideoResponse: response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func process(createVideoResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMUploadTicket
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Create.rawValue)
        }
        
        do
        {
            return try self.uploadTicket(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Create.rawValue)
        }
    }

    func process(uploadVideoResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Upload.rawValue)
        }
    }
    
    func process(activateVideoResponse response: URLResponse?, url: NSURL?, error: NSError?) throws -> String
    {
        do
        {
            _ = try responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Activate.rawValue)
        }

        guard let HTTPResponse = response as? HTTPURLResponse, let location = HTTPResponse.allHeaderFields[type(of: self).LocationKey] as? String else
        {
            throw NSError(domain: UploadErrorDomain.Activate.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Activate response did not contain the required value."])
        }
        
        return location
    }

    func process(videoSettingsResponse response: URLResponse?, url: NSURL?, error: NSError?) throws -> VIMVideo
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try self.responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.VideoSettings.rawValue)
        }
        
        return try self.process(videoSettingsResponse: response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func process(videoSettingsResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMVideo
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.VideoSettings.rawValue)
        }
        
        do
        {
            return try self.video(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.VideoSettings.rawValue)
        }
    }

    func process(deleteVideoResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Delete.rawValue)
        }
    }

    func process(videoResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMVideo
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Video.rawValue)
        }

        do
        {
            return try self.video(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.Video.rawValue)
        }
    }

    // MARK: Private API

    private func videos(from responseObject: AnyObject?) throws -> [VIMVideo]
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMVideo.self, forKeypath: "data")
            
            if let result = mapper.applyMapping(toJSON: dictionary) as? [String: AnyObject], let videos = result["data"] as? [VIMVideo]
            {
                return videos
            }
        }
        
        throw NSError.error(withDomain: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse videos array from responseObject failed")
    }

    private func video(from responseObject: AnyObject?) throws -> VIMVideo
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMVideo.self, forKeypath: "")
            
            if let video = mapper.applyMapping(toJSON: dictionary) as? VIMVideo
            {
                return video
            }
        }
        
        throw NSError.error(withDomain: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse video object from responseObject failed")
    }

    private func user(from responseObject: AnyObject?) throws -> VIMUser
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMUser.self, forKeypath: "")
            
            if let user = mapper.applyMapping(toJSON: dictionary) as? VIMUser
            {
                return user
            }
        }
        
        throw NSError.error(withDomain: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse user object from responseObject failed")
    }

    private func uploadTicket(from responseObject: AnyObject?) throws -> VIMUploadTicket
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMUploadTicket.self, forKeypath: "")
         
            if let uploadTicket = mapper.applyMapping(toJSON: dictionary) as? VIMUploadTicket
            {
                return uploadTicket
            }
        }
        
        throw NSError.error(withDomain: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse uploadTicket object from responseObject failed")
    }
}

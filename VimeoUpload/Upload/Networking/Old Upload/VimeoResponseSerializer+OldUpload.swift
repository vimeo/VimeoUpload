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
    
    func processMeResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMUser
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Me.rawValue)
        }
        
        do
        {
            return try self.userFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Me.rawValue)
        }
    }

    func processMyVideosResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> [VIMVideo]
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.MyVideos.rawValue)
        }
        
        do
        {
            return try self.videosFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.MyVideos.rawValue)
        }
    }

    func processCreateVideoResponse(_ response: URLResponse?, url: NSURL?, error: NSError?) throws -> VIMUploadTicket
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }

        return try self.processCreateVideoResponse(response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func processCreateVideoResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMUploadTicket
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
        
        do
        {
            return try self.uploadTicketFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
    }

    func processUploadVideoResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
    }
    
    func processActivateVideoResponse(_ response: URLResponse?, url: NSURL?, error: NSError?) throws -> String
    {
        do
        {
            _ = try responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Activate.rawValue)
        }

        guard let HTTPResponse = response as? HTTPURLResponse, let location = HTTPResponse.allHeaderFields[type(of: self).LocationKey] as? String else
        {
            throw NSError(domain: UploadErrorDomain.Activate.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Activate response did not contain the required value."])
        }
        
        return location
    }

    func processVideoSettingsResponse(_ response: URLResponse?, url: NSURL?, error: NSError?) throws -> VIMVideo
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try self.responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
        }
        
        return try self.processVideoSettingsResponse(response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func processVideoSettingsResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMVideo
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
        }
        
        do
        {
            return try self.videoFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
        }
    }

    func processDeleteVideoResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Delete.rawValue)
        }
    }

    func processVideoResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMVideo
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Video.rawValue)
        }

        do
        {
            return try self.videoFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Video.rawValue)
        }
    }

    // MARK: Private API

    private func videosFromResponseObject(_ responseObject: AnyObject?) throws -> [VIMVideo]
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
        
        throw NSError.error(with: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse videos array from responseObject failed")
    }

    private func videoFromResponseObject(_ responseObject: AnyObject?) throws -> VIMVideo
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
        
        throw NSError.error(with: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse video object from responseObject failed")
    }

    private func userFromResponseObject(_ responseObject: AnyObject?) throws -> VIMUser
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
        
        throw NSError.error(with: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse user object from responseObject failed")
    }

    private func uploadTicketFromResponseObject(_ responseObject: AnyObject?) throws -> VIMUploadTicket
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
        
        throw NSError.error(with: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse uploadTicket object from responseObject failed")
    }
}

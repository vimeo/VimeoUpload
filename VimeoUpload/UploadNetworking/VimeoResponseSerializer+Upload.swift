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

extension VimeoResponseSerializer
{
    func processCreateVideoResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws -> CreateVideoResponse
    {
//        if let error = error
//        {
//            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
//        }
//        
//        guard let url = url else
//        {
//            throw NSError.nilCreateDownloadUrlError()
//        }
//        
//        guard let data = NSData(contentsOfURL: url) else
//        {
//            throw NSError.nilCreateDataError()
//        }
//        
//        let dictionary: [String: AnyObject]?
//        do
//        {
//            dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]
//        }
//        catch let error as NSError
//        {
//            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
//        }
        
        guard let uploadUri = dictionary?["upload_link_secure"] as? String, let activationUri = dictionary?["complete_uri"] as? String else
        {
            throw NSError.invalidCreateResponseError()
        }
        
        return CreateVideoResponse(uploadUri: uploadUri, activationUri: activationUri)
    }
    
    func processUploadVideoResponse(response: NSURLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
    }
    
    func processActivateVideoResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws -> String
    {
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Activate.rawValue)
        }
        
        guard let HTTPResponse = response as? NSHTTPURLResponse, let location = HTTPResponse.allHeaderFields["Location"] as? String else
        {
            throw NSError.invalidActivateResponseError()
        }
        
        return location
    }

    func processVideoSettingsResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws
    {
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.VideoSettings.rawValue)
        }
    }
    
    // MARK: Private API
    
    // TODO: move this from extension into main class? 
    
    private func dictionaryForDownloadTaskResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws -> [String: AnyObject]?
    {
        if let error = error
        {
            throw error
        }
        
        // TODO: add error domain
        
        guard let url = url else
        {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Url for completed download task is nil"])
        }
        
        guard let data = NSData(contentsOfURL: url) else
        {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data at url for completed download task is nil"])
        }
        
        let dictionary: [String: AnyObject]?
        do
        {
            dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]
        }
        catch let error as NSError
        {
            throw error
        }

        // TODO: add this check to taskDidComplete? So that we can catch upload errors too?
        
        if let dictionary = dictionary, let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode < 200 || httpResponse.statusCode > 299
        {
            // TODO: populate error object with dictionary contents
            // TODO: keep it in sync with localytics keys? Maybe not
            
            let userInfo = [NSLocalizedDescriptionKey: "Invalid http status code for download task"]
            
            throw NSError(domain: "", code: 0, userInfo: userInfo)
        }
        
        return dictionary
    }
    
//        if (data)
//        {
//            userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] = data;
//        }
//
//        self.error = [NSError errorWithDomain:VIMCreateRecordTaskErrorDomain code:0 userInfo:userInfo];

}
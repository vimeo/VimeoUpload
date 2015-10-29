//
//  VimeoResponseSerializer+Upload.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/21/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension VimeoResponseSerializer
{
    func processCreateVideoResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws -> CreateVideoResponse
    {
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }
        
        guard let url = url else
        {
            throw NSError.nilCreateDownloadUrlError()
        }
        
        guard let data = NSData(contentsOfURL: url) else
        {
            throw NSError.nilCreateDataError()
        }
        
        let dictionary: [String: AnyObject]?
        do
        {
            dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.Create.rawValue)
        }

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
}
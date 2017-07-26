//
//  VimeoResponseSerializer+Thumbnail.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking

extension VimeoResponseSerializer
{
    func process(createThumbnailResponse response: URLResponse?, url: URL?, error: NSError?) throws -> VIMThumbnailUploadTicket
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        return try self.process(createThumbnailResponse: response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func process(createThumbnailResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMThumbnailUploadTicket
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        do
        {
            return try self.thumbnailTicket(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
    }
    
    func process(uploadThumbnailResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.UploadThumbnail.rawValue)
        }
    }
    
    func process(activateThumbnailResponse response: URLResponse?, url: URL?, error: NSError?) throws -> VIMPicture
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        return try self.process(activateThumbnailResponse: response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func process(activateThumbnailResponse response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMPicture
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        do
        {
            return try self.vimPicture(from: responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
    }
    
    //MARK: Private methods
    
    private func thumbnailTicket(from responseObject: AnyObject?) throws -> VIMThumbnailUploadTicket
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMThumbnailUploadTicket.self, forKeypath: "")
            
            if let thumbnailTicket = mapper.applyMapping(toJSON: dictionary) as? VIMThumbnailUploadTicket
            {
                return thumbnailTicket
            }
        }
        
        throw NSError.error(withDomain: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse thumbnailTicket object from responseObject failed")
    }
    
    private func vimPicture(from responseObject: AnyObject?) throws -> VIMPicture
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMPicture.self, forKeypath: "")
            
            if let picture = mapper.applyMapping(toJSON: dictionary) as? VIMPicture
            {
                return picture
            }
        }
        
        throw NSError.error(withDomain: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse picture object from responseObject failed")
    }
}

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
    func processCreateThumbnailResponse(_ response: URLResponse?, url: NSURL?, error: NSError?) throws -> VIMThumbnailUploadTicket
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        return try self.processCreateThumbnailResponse(response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func processCreateThumbnailResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMThumbnailUploadTicket
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
            return try self.thumbnailTicketFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
    }
    
    func processUploadThumbnailResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws
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
    
    func processActivateThumbnailResponse(_ response: URLResponse?, url: NSURL?, error: NSError?) throws -> VIMPicture
    {
        let responseObject: [AnyHashable: Any]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url as URL?, error: error)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        return try self.processActivateThumbnailResponse(response, responseObject: responseObject as AnyObject?, error: error)
    }
    
    func processActivateThumbnailResponse(_ response: URLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMPicture
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
            return try self.vimPictureFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
    }
    
    //MARK: Private methods
    
    private func thumbnailTicketFromResponseObject(_ responseObject: AnyObject?) throws -> VIMThumbnailUploadTicket
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
        
        throw NSError.error(with: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse thumbnailTicket object from responseObject failed")
    }
    
    private func vimPictureFromResponseObject(_ responseObject: AnyObject?) throws -> VIMPicture
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
        
        throw NSError.error(with: UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse picture object from responseObject failed")
    }
}

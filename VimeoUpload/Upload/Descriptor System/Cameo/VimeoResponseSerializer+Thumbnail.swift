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
    func processCreateThumbnailResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws -> VIMThumbnailUploadTicket
    {
        let responseObject: [String: AnyObject]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        return try self.processCreateThumbnailResponse(response, responseObject: responseObject, error: error)
    }
    
    func processCreateThumbnailResponse(response: NSURLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMThumbnailUploadTicket
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        do
        {
            return try self.thumbnailTicketFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.CreateThumbnail.rawValue)
        }
    }
    
    func processUploadThumbnailResponse(response: NSURLResponse?, responseObject: AnyObject?, error: NSError?) throws
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.UploadThumbnail.rawValue)
        }
    }
    
    func processActivateThumbnailResponse(response: NSURLResponse?, url: NSURL?, error: NSError?) throws -> VIMPicture
    {
        let responseObject: [String: AnyObject]?
        do
        {
            responseObject = try responseObjectFromDownloadTaskResponse(response: response, url: url, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        return try self.processActivateThumbnailResponse(response, responseObject: responseObject, error: error)
    }
    
    func processActivateThumbnailResponse(response: NSURLResponse?, responseObject: AnyObject?, error: NSError?) throws -> VIMPicture
    {
        do
        {
            try checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        do
        {
            return try self.vimPictureFromResponseObject(responseObject)
        }
        catch let error as NSError
        {
            throw error.errorByAddingDomain(UploadErrorDomain.CreateThumbnail.rawValue)
        }
    }
    
    //MARK: Private methods
    
    private func thumbnailTicketFromResponseObject(responseObject: AnyObject?) throws -> VIMThumbnailUploadTicket
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMThumbnailUploadTicket.self, forKeypath: "")
            
            if let thumbnailTicket = mapper.applyMappingToJSON(dictionary) as? VIMThumbnailUploadTicket
            {
                return thumbnailTicket
            }
        }
        
        throw NSError.errorWithDomain(UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse thumbnailTicket object from responseObject failed")
    }
    
    private func vimPictureFromResponseObject(responseObject: AnyObject?) throws -> VIMPicture
    {
        if let dictionary = responseObject as? [String: AnyObject]
        {
            let mapper = VIMObjectMapper()
            mapper.addMappingClass(VIMPicture.self, forKeypath: "")
            
            if let picture = mapper.applyMappingToJSON(dictionary) as? VIMPicture
            {
                return picture
            }
        }
        
        throw NSError.errorWithDomain(UploadErrorDomain.VimeoResponseSerializer.rawValue, code: nil, description: "Attempt to parse picture object from responseObject failed")
    }
}

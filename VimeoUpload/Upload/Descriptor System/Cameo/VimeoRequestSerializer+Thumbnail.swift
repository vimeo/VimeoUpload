//
//  VimeoRequestSerializer+Thumbnail.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import AVFoundation
import VimeoNetworking

extension VimeoRequestSerializer
{
    func createThumbnailRequestWithUri(uri: String) throws -> NSMutableURLRequest
    {
        let url = NSURL(string: "\(uri)/pictures", relativeToURL: VimeoBaseURLString)!
        
        var error: NSError?
        let request = self.requestWithMethod("POST", URLString: url.absoluteString!, parameters: nil, error: &error)
        
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        return request
    }
    
    func activateThumbnailRequestWithUri(uri: String) throws -> NSMutableURLRequest
    {
        let url = NSURL(string: "\(uri)", relativeToURL: VimeoBaseURLString)!
        
        var error: NSError?
        let activationParams = ["active" : "true"]
        let request = self.requestWithMethod("PATCH", URLString: url.absoluteString!, parameters: activationParams, error: &error)
        
        if let error = error
        {
            throw error.errorByAddingDomain(UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        return request
    }
    
    func uploadThumbnailRequestWithSource(source: NSURL, destination: String) throws -> NSMutableURLRequest {
        
        guard let path = source.path where NSFileManager.defaultManager().fileExistsAtPath(path) else {
            throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to construct upload request but the source file does not exist."])
        }
        
        var error: NSError?
        let request = self.requestWithMethod("PUT", URLString: destination, parameters: nil, error: &error)
        if let error = error {
            throw error.errorByAddingDomain(UploadErrorDomain.UploadThumbnail.rawValue)
        }
        
        let asset = AVURLAsset(URL: source)
        
        let fileSize: NSNumber
        do {
            fileSize = try asset.fileSize()
        } catch let error as NSError {
            throw error.errorByAddingDomain(UploadErrorDomain.UploadThumbnail.rawValue)
        }
        
        request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("bytes 0-\(fileSize)/\(fileSize)", forHTTPHeaderField: "Content-Range")
        
        return request
    }
}


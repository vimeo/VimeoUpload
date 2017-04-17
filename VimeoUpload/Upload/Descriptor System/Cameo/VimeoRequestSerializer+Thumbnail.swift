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
    func createThumbnailRequest(with uri: String) throws -> NSMutableURLRequest
    {
        let url = NSURL(string: "\(uri)/pictures", relativeTo: VimeoBaseURLString)!
        
        var error: NSError?
        let request = self.request(withMethod: "POST", urlString: url.absoluteString!, parameters: nil, error: &error)
        
        if let error = error
        {
            throw error.error(byAddingDomain: UploadErrorDomain.CreateThumbnail.rawValue)
        }
        
        return request
    }
    
    func activateThumbnailRequest(with uri: String) throws -> NSMutableURLRequest
    {
        let url = NSURL(string: "\(uri)", relativeTo: VimeoBaseURLString)!
        
        var error: NSError?
        let activationParams = ["active" : "true"]
        let request = self.request(withMethod: "PATCH", urlString: url.absoluteString!, parameters: activationParams, error: &error)
        
        if let error = error
        {
            throw error.error(byAddingDomain: UploadErrorDomain.ActivateThumbnail.rawValue)
        }
        
        return request
    }
    
    func uploadThumbnailRequest(with source: NSURL, destination: String) throws -> NSMutableURLRequest {
        
        guard let path = source.path, FileManager.default.fileExists(atPath: path) else {
            throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to construct upload request but the source file does not exist."])
        }
        
        var error: NSError?
        let request = self.request(withMethod: "PUT", urlString: destination, parameters: nil, error: &error)
        if let error = error {
            throw error.error(byAddingDomain: UploadErrorDomain.UploadThumbnail.rawValue)
        }
        
        let asset = AVURLAsset(url: source as URL)
        
        let fileSize: NSNumber
        do {
            fileSize = try asset.fileSize()
        } catch let error as NSError {
            throw error.error(byAddingDomain: UploadErrorDomain.UploadThumbnail.rawValue)
        }
        
        request.setValue("\(fileSize)", forHTTPHeaderField: "Content-Length")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("bytes 0-\(fileSize)/\(fileSize)", forHTTPHeaderField: "Content-Range")
        
        return request
    }
}


//
//  VimeoSessionManager+ThumbnailUpload.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking

extension VimeoSessionManager
{
    func createThumbnailDownloadTask(uri uri: VideoUri) throws -> NSURLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createThumbnailRequestWithUri(uri)
        
        let task = self.downloadTaskWithRequest(request, progress: nil, destination: nil, completionHandler: nil)
        task.taskDescription = UploadTaskDescription.CreateThumbnail.rawValue
        
        return task
    }
    
    func uploadThumbnailTask(source source: NSURL, destination: String, completionHandler: ErrorBlock?) throws -> NSURLSessionUploadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).uploadThumbnailRequestWithSource(source, destination: destination)
        
        let task = self.uploadTaskWithRequest(request, fromFile: source, progress: nil) { [weak self] (response, responseObject, error) in
            
            guard let strongSelf = self, completionHandler = completionHandler else {
                return
            }
            
            do {
                try (strongSelf.responseSerializer as! VimeoResponseSerializer).processUploadThumbnailResponse(response, responseObject: responseObject, error: error)
                completionHandler(error: nil)
            } catch let error as NSError {
                completionHandler(error: error)
            }
            
        }
        
        task.taskDescription = UploadTaskDescription.UploadThumbnail.rawValue
        
        return task
    }
    
    func activateThumbnailTask(activationUri activationUri: String) throws -> NSURLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).activateThumbnailRequestWithUri(activationUri)
        
        let task = self.downloadTaskWithRequest(request, progress: nil, destination: nil, completionHandler: nil)
        task.taskDescription = UploadTaskDescription.ActivateThumbnail.rawValue
        
        return task
    }
}

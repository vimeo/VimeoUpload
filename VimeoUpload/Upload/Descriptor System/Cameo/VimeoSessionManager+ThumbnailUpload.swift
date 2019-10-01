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
    func createThumbnailDownloadTask(uri: VideoUri) throws -> URLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createThumbnailRequest(with: uri)
        
        let task = self.httpSessionManager.downloadTask(with: request as URLRequest, progress: nil, destination: nil, completionHandler: nil)
        task.taskDescription = UploadTaskDescription.CreateThumbnail.rawValue
        
        return task
    }
    
    func uploadThumbnailTask(source: URL, destination: String, completionHandler: ErrorBlock?) throws -> URLSessionUploadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).uploadThumbnailRequest(with: source, destination: destination)
        
        let task = self.httpSessionManager.uploadTask(with: request as URLRequest, fromFile: source as URL, progress: nil) { [weak self] (response, responseObject, error) in
            
            guard let strongSelf = self, let completionHandler = completionHandler else {
                return
            }
            
            do {
                try strongSelf.jsonResponseSerializer.process(uploadThumbnailResponse: response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                completionHandler(nil)
            } catch let error as NSError {
                completionHandler(error)
            }
            
        }
        
        task.taskDescription = UploadTaskDescription.UploadThumbnail.rawValue
        
        return task
    }
    
    func activateThumbnailTask(activationUri: String) throws -> URLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).activateThumbnailRequest(with: activationUri)
        
        let task = self.httpSessionManager.downloadTask(with: request as URLRequest, progress: nil, destination: nil, completionHandler: nil)
        task.taskDescription = UploadTaskDescription.ActivateThumbnail.rawValue
        
        return task
    }
}

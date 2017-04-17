//
//  VimeoSessionManager+Upload.swift
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

enum UploadTaskDescription: String
{
    case Me = "Me"
    case MyVideos = "MyVideos"
    case CreateVideo = "CreateVideo"
    case UploadVideo = "UploadVideo"
    case ActivateVideo = "ActivateVideo"
    case VideoSettings = "VideoSettings"
    case DeleteVideo = "DeleteVideo"
    case Video = "Video"
    case CreateThumbnail = "CreateThumbnail"
    case UploadThumbnail = "UploadThumbnail"
    case ActivateThumbnail = "ActivateThumbnail"
}

extension VimeoSessionManager
{
    public func meDataTask(completionHandler: @escaping UserCompletionHandler) throws -> URLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).meRequest()

        let task = self.dataTask(with: request as URLRequest, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async(execute: { [weak self] () -> Void in
                guard let strongSelf = self else
                {
                    return
                }
                
                do
                {
                    let user = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processMeResponse(response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                    completionHandler(user, nil)
                }
                catch let error as NSError
                {
                    completionHandler(nil, error)
                }
            })
        })
        
        task.taskDescription = UploadTaskDescription.Me.rawValue
        
        return task
    }

    public func myVideosDataTask(completionHandler: @escaping VideosCompletionHandler) throws -> URLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).myVideosRequest()
        
        let task = self.dataTask(with: request as URLRequest, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async(execute: { [weak self] () -> Void in
                guard let strongSelf = self else
                {
                    return
                }
                
                do
                {
                    let videos = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processMyVideosResponse(response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                    completionHandler(videos, nil)
                }
                catch let error as NSError
                {
                    completionHandler(nil, error)
                }
            })
        })
        
        task.taskDescription = UploadTaskDescription.MyVideos.rawValue
        
        return task
    }

    public func createVideoDownloadTask(url: NSURL) throws -> URLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createVideoRequest(with: url)

        let task = self.downloadTask(with: request as URLRequest, progress: nil, destination: nil, completionHandler: nil)
        
        task.taskDescription = UploadTaskDescription.CreateVideo.rawValue
        
        return task
    }
    
    func uploadVideoTask(source: NSURL, destination: String, completionHandler: ErrorBlock?) throws -> URLSessionUploadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).uploadVideoRequest(with: source, destination: destination)
        
        let task = self.uploadTask(with: request as URLRequest, fromFile: source as URL, progress: nil, completionHandler: { [weak self] (response, responseObject, error) -> Void in

            guard let strongSelf = self, let completionHandler = completionHandler else
            {
                return
            }
            
            do
            {
                try (strongSelf.responseSerializer as! VimeoResponseSerializer).processUploadVideoResponse(response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                completionHandler(nil)
            }
            catch let error as NSError
            {
                completionHandler(error)
            }

        })
        
        task.taskDescription = UploadTaskDescription.UploadVideo.rawValue
        
        return task
    }
    
    // For use with background sessions, use session delegate methods for destination and completion
    func activateVideoDownloadTask(uri activationUri: String) throws -> URLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).activateVideoRequest(withURI: activationUri)
        
        let task = self.downloadTask(with: request as URLRequest, progress: nil, destination: nil, completionHandler: nil)
        
        task.taskDescription = UploadTaskDescription.ActivateVideo.rawValue
        
        return task
    }    

    // For use with background sessions, use session delegate methods for destination and completion
    func videoSettingsDownloadTask(videoUri: String, videoSettings: VideoSettings) throws -> URLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).videoSettingsRequestWithUri(videoUri, videoSettings: videoSettings)
        
        let task = self.downloadTask(with: request as URLRequest, progress: nil, destination: nil, completionHandler: nil)
        
        task.taskDescription = UploadTaskDescription.VideoSettings.rawValue
        
        return task
    }

    public func videoSettingsDataTask(videoUri: String, videoSettings: VideoSettings, completionHandler: @escaping VideoCompletionHandler) throws -> URLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).videoSettingsRequestWithUri(videoUri, videoSettings: videoSettings)
        
        let task = self.dataTask(with: request as URLRequest, completionHandler: { (response, responseObject, error) -> Void in
            
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async(execute: { [weak self] () -> Void in
                guard let strongSelf = self else
                {
                    return
                }
                
                do
                {
                    let video = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processVideoSettingsResponse(response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                    completionHandler(video, nil)
                }
                catch let error as NSError
                {
                    completionHandler(nil, error)
                }
            })
        })
        
        task.taskDescription = UploadTaskDescription.VideoSettings.rawValue
        
        return task
    }
    
    func deleteVideoDataTask(videoUri: String, completionHandler: @escaping ErrorBlock) throws -> URLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).deleteVideoRequestWithUri(videoUri)
        
        let task = self.dataTask(with: request as URLRequest, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            do
            {
                try (strongSelf.responseSerializer as! VimeoResponseSerializer).processDeleteVideoResponse(response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                completionHandler(nil)
            }
            catch let error as NSError
            {
                completionHandler(error)
            }
        })
        
        task.taskDescription = UploadTaskDescription.DeleteVideo.rawValue
        
        return task
    }

    func videoDataTask(videoUri: String, completionHandler: @escaping VideoCompletionHandler) throws -> URLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).videoRequestWithUri(videoUri)
        
        let task = self.dataTask(with: request as URLRequest, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            do
            {
                let video = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processVideoResponse(response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                completionHandler(video, nil)
            }
            catch let error as NSError
            {
                completionHandler(nil, error)
            }
        })
        
        task.taskDescription = UploadTaskDescription.Video.rawValue
        
        return task
    }
}

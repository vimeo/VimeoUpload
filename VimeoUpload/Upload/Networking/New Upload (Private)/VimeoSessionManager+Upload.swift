//
//  VimeoSessionManager+SimpleUpload.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/21/15.
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

public typealias UploadParameters = [String: Any]

extension VimeoSessionManager
{
    public struct Constants
    {
        public static let ApproachKey = "approach"
        public static let StreamingApproachValue = VIMUpload.UploadApproach.Streaming.rawValue
        public static let DefaultUploadParameters: UploadParameters = VimeoUploader<VideoDescriptor>.DefaultUploadStrategy.createVideoUploadParameters()
    }
    
    func createVideoDataTask(url: URL, videoSettings: VideoSettings?, uploadParameters: UploadParameters, completionHandler: @escaping VideoCompletionHandler) throws -> URLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createVideoRequest(with: url, videoSettings: videoSettings, uploadParameters: uploadParameters)

        let task = self.dataTask(with: request as URLRequest, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async(execute: { [weak self] () -> Void in
                guard let strongSelf = self else
                {
                    return
                }
                
                do
                {
                    let video = try (strongSelf.responseSerializer as! VimeoResponseSerializer).process(videoResponse: response, responseObject: responseObject as AnyObject?, error: error as NSError?)
                    completionHandler(video, nil)
                }
                catch let error as NSError
                {
                    completionHandler(nil, error)
                }
            })
        })
        
        task.taskDescription = UploadTaskDescription.CreateVideo.rawValue
        
        return task
    }
    
    func createVideoDownloadTask(url: URL, videoSettings: VideoSettings?, uploadParameters: UploadParameters) throws -> URLSessionDownloadTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createVideoRequest(with: url, videoSettings: videoSettings, uploadParameters: uploadParameters)
        
        let task = self.downloadTask(with: request as URLRequest, progress: nil, destination: nil, completionHandler: nil)
        
        task.taskDescription = UploadTaskDescription.CreateVideo.rawValue
        
        return task
    }
    
    func uploadVideoTask(source: URL, request: URLRequest, completionHandler: ErrorBlock?) -> URLSessionUploadTask
    {
        let task = self.uploadTask(with: request, fromFile: source, progress: nil, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            guard let strongSelf = self, let completionHandler = completionHandler else
            {
                return
            }
            
            do
            {
                try (strongSelf.responseSerializer as! VimeoResponseSerializer).process(uploadVideoResponse: response, responseObject: responseObject as AnyObject?, error: error as NSError?)
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
}

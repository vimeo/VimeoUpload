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
    
    func createVideoDataTask(url: URL, videoSettings: VideoSettings?, uploadParameters: UploadParameters, completionHandler: @escaping VideoCompletionHandler) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.createVideoRequest(with: url, videoSettings: videoSettings, uploadParameters: uploadParameters) as URLRequest

        return self.request(request) { [jsonResponseSerializer] (sessionManagingResult: SessionManagingResult<JSON>) in
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async(execute: {
                switch sessionManagingResult.result {
                case .failure(let error):
                    completionHandler(nil, error as NSError)
                case .success(let json):
                    do {                        
                        let video = try jsonResponseSerializer.process(
                            videoResponse: sessionManagingResult.response,
                            responseObject: json as AnyObject,
                            error: nil
                        )
                        completionHandler(video, nil)
                    } catch {
                        completionHandler(nil, error as NSError)
                    }
                }
            })
        }

    }
    
    func createVideoDownloadTask(url: URL, videoSettings: VideoSettings?, uploadParameters: UploadParameters) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.createVideoRequest(with: url, videoSettings: videoSettings, uploadParameters: uploadParameters) as URLRequest        
        let task = self.download(request) { _ in }
        return task
    }
    
    func uploadVideoTask(source: URL, request: URLRequest, completionHandler: ErrorBlock?) -> Task?
    {
        return self.upload(request, sourceFile: source) { [jsonResponseSerializer] sessionManagingResult in
            switch sessionManagingResult.result {
            case .failure(let error):
                completionHandler?(error as NSError)
            case .success(let json):
                do {
                    try jsonResponseSerializer.process(
                        uploadVideoResponse: sessionManagingResult.response,
                        responseObject: json as AnyObject,
                        error: nil
                    )
                    completionHandler?(nil)
                } catch {
                    completionHandler?(error as NSError)
                }
            }
        }
    }
}

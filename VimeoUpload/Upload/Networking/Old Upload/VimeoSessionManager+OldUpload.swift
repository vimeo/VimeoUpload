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

extension VimeoSessionManager
{
    public func myVideosDataTask(completionHandler: @escaping VideosCompletionHandler) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.myVideosRequest() as URLRequest
        return self.request(request) { [jsonResponseSerializer] sessionManagingResult in
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async {
                switch sessionManagingResult.result {
                case .failure(let error as NSError):
                    completionHandler(nil, error)
                case .success:
                    do {
                        let response = sessionManagingResult.response
                        let json = try jsonResponseSerializer.responseObjectFromDownloadTaskResponse(
                            response: response,
                            url: response?.url,
                            error: nil
                        ) as AnyObject
                        let videos = try jsonResponseSerializer.process(
                            myVideosResponse: response,
                            responseObject: json,
                            error: nil
                        )
                        completionHandler(videos, nil)
                    } catch let error as NSError {
                        completionHandler(nil, error)
                    }
                }
            }
        }
    }

    public func createVideoDownloadTask(url: URL) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.createVideoRequest(with: url) as URLRequest
        return self.download(request) { _ in }
    }
    
    func uploadVideoTask(source: URL, destination: String, completionHandler: ErrorBlock?) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.uploadVideoRequest(with: source, destination: destination) as URLRequest
        return self.upload(request, sourceFile: source) { [jsonResponseSerializer] sessionManagingResult in
            switch sessionManagingResult.result {
            case .failure(let error):
                completionHandler?(error as NSError)
            case .success:
                do
                {
                    let response = sessionManagingResult.response
                    let json = try jsonResponseSerializer.responseObjectFromDownloadTaskResponse(response: response, url: response?.url, error: nil) as AnyObject
                    try jsonResponseSerializer.process(uploadVideoResponse: response, responseObject: json, error: nil)
                    completionHandler?(nil)
                } catch let error as NSError {
                    completionHandler?(error)
                }
            }
        }
    }
    
    // For use with background sessions, use session delegate methods for destination and completion
    func activateVideoDownloadTask(uri activationUri: String) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.activateVideoRequest(withURI: activationUri) as URLRequest
        return self.download(request) { _ in }
    }

    // For use with background sessions, use session delegate methods for destination and completion
    func videoSettingsDownloadTask(videoUri: String, videoSettings: VideoSettings) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.videoSettingsRequest(with: videoUri, videoSettings: videoSettings) as URLRequest
        return self.download(request) { _ in }
    }

    public func videoSettingsDataTask(videoUri: String, videoSettings: VideoSettings, completionHandler: @escaping VideoCompletionHandler) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.videoSettingsRequest(with: videoUri, videoSettings: videoSettings) as URLRequest
        return self.request(request) { [jsonResponseSerializer] sessionManagingResult in
            // Do model parsing on a background thread
            DispatchQueue.global(qos: .default).async {
                switch sessionManagingResult.result {
                case .failure(let error):
                    completionHandler(nil, error as NSError)
                case .success:
                    do {
                        let response = sessionManagingResult.response
                        let json = try jsonResponseSerializer.responseObjectFromDownloadTaskResponse(
                            response: response,
                            url: response?.url,
                            error: nil
                        ) as AnyObject
                        let video = try jsonResponseSerializer.process(videoSettingsResponse: response, responseObject: json, error: nil)
                        completionHandler(video, nil)
                    } catch let error as NSError {
                        completionHandler(nil, error)
                    }
                }
            }
        }
    }
    
    func deleteVideoDataTask(videoUri: String, completionHandler: @escaping ErrorBlock) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.deleteVideoRequest(with: videoUri) as URLRequest
        return self.request(request) { [jsonResponseSerializer] sessionManagingResult in
            switch sessionManagingResult.result {
            case .failure(let error):
                completionHandler(error as NSError)
            case .success:
                do {
                    let response = sessionManagingResult.response
                    let json = try jsonResponseSerializer.responseObjectFromDownloadTaskResponse(
                        response: response,
                        url: response?.url,
                        error: nil
                    ) as AnyObject
                    try jsonResponseSerializer.process(deleteVideoResponse: response, responseObject: json, error: nil)
                    completionHandler(nil)
                } catch let error as NSError {
                    completionHandler(error)
                }
            }
        }
    }

    func videoDataTask(videoUri: String, completionHandler: @escaping VideoCompletionHandler) throws -> Task?
    {
        let request = try self.jsonRequestSerializer.videoRequest(with: videoUri) as URLRequest
        return self.request(request) { [jsonResponseSerializer] sessionManagingResult in
            switch sessionManagingResult.result {
            case .failure(let error as NSError):
                completionHandler(nil, error)
            case .success:
                do {
                    let response = sessionManagingResult.response
                    let json = try jsonResponseSerializer.responseObjectFromDownloadTaskResponse(
                        response: response,
                        url: response?.url,
                        error: nil
                    ) as AnyObject
                    let video = try jsonResponseSerializer.process(videoResponse: response, responseObject: json, error: nil)
                    completionHandler(video, nil)
                } catch let error as NSError {
                    completionHandler(nil, error)
                }
            }
        }
    }
}

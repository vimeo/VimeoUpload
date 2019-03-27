//
//  CreateVideoOperation.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/9/15.
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

@objc public class CreateVideoOperation: ConcurrentOperation
{
    private let sessionManager: VimeoSessionManager
    private let url: URL
    private let videoSettings: VideoSettings?
    private let uploadParameters: UploadParameters
    
    private var task: URLSessionDataTask?

    @objc public var result: VIMVideo?
    @objc public var error: NSError?
    
    // MARK: - Initialization

    @objc public required init(sessionManager: VimeoSessionManager, url: URL, videoSettings: VideoSettings?, uploadParameters: UploadParameters)
    {
        self.sessionManager = sessionManager
        self.url = url
        self.videoSettings = videoSettings
        self.uploadParameters = uploadParameters
        
        super.init()
    }
    
    deinit
    {
        self.task?.cancel()
    }
    
    // MARK: Overrides

    @objc override public func main()
    {
        if self.isCancelled
        {
            return
        }
        
        do
        {
            self.task = try self.sessionManager.createVideoDataTask(url: url, videoSettings: videoSettings, uploadParameters: uploadParameters, completionHandler: { [weak self] (video, error) -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                strongSelf.task = nil
                
                if strongSelf.isCancelled
                {
                    return
                }
                
                if let error = error
                {
                    strongSelf.error = error.error(byAddingDomain: UploadErrorDomain.CreateVideoOperation.rawValue)
                }
                else if let video = video
                {
                    strongSelf.result = video
                }
                else
                {
                    fatalError("Execution should never reach this point")
                }
                
                strongSelf.state = .finished
            })
            
            self.task?.resume()
        }
        catch let error as NSError
        {
            self.error = error.error(byAddingDomain: UploadErrorDomain.CreateVideoOperation.rawValue)
            self.state = .finished
        }
    }
    
    @objc override public func cancel()
    {
        super.cancel()
        
        self.task?.cancel()
        self.task = nil
    }
}

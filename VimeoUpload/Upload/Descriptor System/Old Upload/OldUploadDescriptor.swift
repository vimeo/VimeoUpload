//
//  OldUploadDescriptor.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/18/15.
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

@objc public class OldUploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    // MARK:
    
    let url: URL
    let videoSettings: VideoSettings?

    // MARK:
    
    private(set) var uploadTicket: VIMUploadTicket? // Create response
    @objc public var videoUri: String? // Activate response
    private(set) var video: VIMVideo? // Settings response

    // MARK:
    
    private(set) var currentRequest = OldUploadRequest.Create
    {
        didSet
        {
            let identifier = self.identifier ?? ""
            print("\(self.currentRequest.rawValue) \(identifier)")
        }
    }
    
    // MARK: VideoDescriptor
    
    @objc public var descriptorType: VideoDescriptorType
    {
        return .upload
    }
    
    @objc public var progressDescriptor: ProgressDescriptor
    {
        return self
    }

    // MARK: - Initialization
    
    @objc required public init()
    {
        fatalError("init() has not been implemented")
    }

    @objc public init(url: URL, videoSettings: VideoSettings? = nil)
    {
        self.url = url
        self.videoSettings = videoSettings
        
        super.init()
    }

    // MARK: Overrides
    
    @objc override public func prepare(sessionManager: VimeoSessionManager) throws
    {
        do
        {
            try self.transitionToState(request: .Create, sessionManager: sessionManager)
        }
        catch let error as NSError
        {
            self.currentTaskIdentifier = nil
            self.error = error
            self.state = .finished
            
            throw error // Propagate this out so that DescriptorManager can remove the descriptor from the set
        }
    }
    
    @objc override public func resume(sessionManager: VimeoSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
        if let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTask(for: identifier),
            let progress = sessionManager.uploadProgress(for: task)
        {
            self.progress = progress
        }
    }

    @objc override public func cancel(sessionManager: VimeoSessionManager)
    {
        super.cancel(sessionManager: sessionManager)
        
        FileManager.default.deleteFile(at: self.url)
    }
    
    // If necessary, resume the current task and re-connect progress objects

    @objc override public func didLoadFromCache(sessionManager: VimeoSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTask(for: identifier),
            let progress = sessionManager.uploadProgress(for: task) else
        {
            // This error is thrown if you initiate an upload and then kill the app from the multitasking view in mid-upload
            // Upon reopening the app, the descriptor is loaded but no longer has a task
            
            FileManager.default.deleteFile(at: self.url)
            
            let error = NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
            self.error = error // TODO: Whenever we set error delete local file? Same for download?
            self.currentTaskIdentifier = nil
            self.state = .finished
            
            throw error
        }

        self.progress = progress
    }
    
    @objc override public func taskDidFinishDownloading(sessionManager: VimeoSessionManager, task: URLSessionDownloadTask, url: URL) -> URL?
    {
        let responseSerializer = sessionManager.vimeoResponseSerializer
        
        do
        {
            switch self.currentRequest
            {
            case .Create:
                self.uploadTicket = try responseSerializer.process(createVideoResponse: task.response, url: url, error: error)
                
            case .Upload:
                break
                
            case .Activate:
                self.videoUri = try responseSerializer.process(activateVideoResponse: task.response, url: url, error: error)
                
            case .Settings:
                self.video = try responseSerializer.process(videoSettingsResponse: task.response, url: url, error: error)
            }
        }
        catch let error as NSError
        {
            self.error = error
            self.currentTaskIdentifier = nil
            self.state = .finished
        }

        return nil
    }
    
    @objc override public func taskDidComplete(sessionManager: VimeoSessionManager, task: URLSessionTask, error: NSError?)
    {
        if self.currentRequest == .Upload
        {
            FileManager.default.deleteFile(at: self.url)
        }

        if self.error == nil
        {
            if let taskError = task.error // task.error is reserved for client-side errors, so check it first
            {
                let domain = self.errorDomain(forRequest: self.currentRequest)
                self.error = (taskError as NSError).error(byAddingDomain: domain)
            }
            else if let error = error
            {
                let domain = self.errorDomain(forRequest: self.currentRequest)
                self.error = error.error(byAddingDomain: domain)
            }
        }
        
        let nextRequest = OldUploadRequest.nextRequest(self.currentRequest)
        if self.error != nil || nextRequest == nil || (nextRequest == .Settings && self.videoSettings == nil)
        {
            self.currentTaskIdentifier = nil
            self.state = .finished

            return
        }
        
        do
        {
            try self.transitionToState(request: nextRequest!, sessionManager: sessionManager)
            self.resume(sessionManager: sessionManager)
        }
        catch let error as NSError
        {
            self.error = error
            self.currentTaskIdentifier = nil
            self.state = .finished
        }
    }
    
    // MARK: Private API
    
    private func transitionToState(request: OldUploadRequest, sessionManager: VimeoSessionManager) throws
    {
        self.currentRequest = request
        let task = try self.task(forRequest: request, sessionManager: sessionManager)
        self.currentTaskIdentifier = task.taskIdentifier
    }
    
    private func task(forRequest request: OldUploadRequest, sessionManager: VimeoSessionManager) throws -> URLSessionTask
    {
        switch request
        {
        case .Create:
            return try sessionManager.createVideoDownloadTask(url: self.url)
            
        case .Upload:
            guard let uploadUri = self.uploadTicket?.uploadLinkSecure else
            {
                throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }

            return try sessionManager.uploadVideoTask(source: self.url, destination: uploadUri, completionHandler: nil)
            
        case .Activate:
            guard let activationUri = self.uploadTicket?.completeUri else
            {
                throw NSError(domain: UploadErrorDomain.Activate.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Activate response did not contain the required values."])
            }
            
            return try sessionManager.activateVideoDownloadTask(uri: activationUri)

        case .Settings:
            guard let videoUri = self.videoUri, let videoSettings = self.videoSettings else
            {
                throw NSError(domain: UploadErrorDomain.VideoSettings.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Video settings response did not contain the required values."])
            }
            
            return try sessionManager.videoSettingsDownloadTask(videoUri: videoUri, videoSettings: videoSettings)
        }
    }

    private func errorDomain(forRequest request: OldUploadRequest) -> String
    {
        switch request
        {
        case .Create:
            return UploadErrorDomain.Create.rawValue

        case .Upload:
            return UploadErrorDomain.Upload.rawValue

        case .Activate:
            return UploadErrorDomain.Activate.rawValue

        case .Settings:
            return UploadErrorDomain.VideoSettings.rawValue
        }
    }
    
    // MARK: NSCoding
    
    @objc required public init(coder aDecoder: NSCoder)
    {
        self.url = aDecoder.decodeObject(forKey: "url") as! URL // If force unwrap fails we have a big problem
        self.videoSettings = aDecoder.decodeObject(forKey: "videoSettings") as? VideoSettings
        self.uploadTicket = aDecoder.decodeObject(forKey: "uploadTicket") as? VIMUploadTicket
        self.videoUri = aDecoder.decodeObject(forKey: "videoUri") as? String
        self.currentRequest = OldUploadRequest(rawValue: aDecoder.decodeObject(forKey: "currentRequest") as! String)!

        super.init(coder: aDecoder)
    }
    
    @objc override public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.url, forKey: "url")
        aCoder.encode(self.videoSettings, forKey: "videoSettings")
        aCoder.encode(self.uploadTicket, forKey: "uploadTicket")
        aCoder.encode(self.videoUri, forKey: "videoUri")
        aCoder.encode(self.currentRequest.rawValue, forKey: "currentRequest")
        
        super.encode(with: aCoder)
    }
}

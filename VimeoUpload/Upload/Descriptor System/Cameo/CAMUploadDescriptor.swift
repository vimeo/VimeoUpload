//
//  CAMUploadDescriptor.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/27/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import AFNetworking
import VimeoNetworking

@objc public class CAMUploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    let videoUrl: URL
    let videoSettings: VideoSettings?
    let thumbnailUrl: URL?
    
    @objc public private(set) var uploadTicket: VIMUploadTicket?
    @objc public private(set) var pictureTicket: VIMThumbnailUploadTicket?
    @objc public private(set) var picture: VIMPicture?
    
    private var currentRequest = CAMUploadRequest.CreateVideo
    {
        didSet
        {
            print("\(self.currentRequest.rawValue) \(String(describing: self.identifier))")
        }
    }
 
    private struct ArchiverConstants {
        static let VideoUrlKey = "videoUrl"
        static let ThumbnailUrlKey = "thumbnailUrl"
        static let VideoSettingsKey = "videoSettings"
        static let UploadTicketKey = "uploadTicket"
        static let CurrentRequestKey = "currentRequest"
    }
    
    //MARK: VideoDescriptor Protocol
    
    @objc public var descriptorType: VideoDescriptorType
    {
        return .upload
    }
    
    @objc public var videoUri: VideoUri?
    
    @objc public var progressDescriptor: ProgressDescriptor
    {
        return self
    }
    
    //MARK: Initializers
    
    @objc required public init()
    {
        fatalError("default init() should not be used, use init(videoUrl:videoSettings:thumbnailUrl:) instead")
    }
    
    @objc public init(videoUrl: URL, videoSettings: VideoSettings? = nil, thumbnailUrl: URL?)
    {
        self.videoUrl = videoUrl
        self.videoSettings = videoSettings
        self.thumbnailUrl = thumbnailUrl
        
        super.init()
    }
    
    //MARK: Overrides
    
    @objc override public func prepare(sessionManager: AFURLSessionManager) throws
    {
        let sessionManager = sessionManager as! VimeoSessionManager
        
        do
        {
            try self.transitionToState(request: .CreateVideo, sessionManager: sessionManager)
        }
        catch let error as NSError
        {
            self.currentTaskIdentifier = nil
            self.error = error
            self.state = .finished
            
            throw error
        }
    }
    
    @objc override public func resume(sessionManager: AFURLSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
        if let identifier = self.currentTaskIdentifier, let task = sessionManager.uploadTask(for: identifier), let progress = sessionManager.uploadProgress(for: task)
        {
            self.progress = progress
        }
    }
    
    @objc override public func cancel(sessionManager: AFURLSessionManager)
    {
        super.cancel(sessionManager: sessionManager)
        
        FileManager.default.deleteFile(at: self.videoUrl)
        
        if let thumbnailUrl = self.thumbnailUrl {
            FileManager.default.deleteFile(at: thumbnailUrl)
        }
    }
    
    @objc override public func didLoadFromCache(sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier, let task = sessionManager.uploadTask(for: identifier), let progress = sessionManager.uploadProgress(for: task) else
        {
            FileManager.default.deleteFile(at: self.videoUrl)
            
            if let thumbnailUrl = self.thumbnailUrl {
                FileManager.default.deleteFile(at: thumbnailUrl)
            }
            
            let error = NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
            self.error = error // TODO: Whenever we set error delete local file? Same for download?
            self.currentTaskIdentifier = nil
            self.state = .finished
            
            throw error
        }
        
        self.progress = progress
    }
    
    @objc override public func taskDidFinishDownloading(sessionManager: AFURLSessionManager, task: URLSessionDownloadTask, url: URL) -> URL?
    {
        let sessionManager = sessionManager as! VimeoSessionManager
        let responseSerializer = sessionManager.responseSerializer as! VimeoResponseSerializer
        
        do
        {
            switch self.currentRequest
            {
            case .CreateVideo:
                self.uploadTicket = try responseSerializer.process(createVideoResponse: task.response, url: url, error: error)
                
            case .UploadVideo:
                break
                
            case .CreateThumbnail:
                self.pictureTicket = try responseSerializer.process(createThumbnailResponse: task.response, url: url, error: error)
                
            case .UploadThumbnail:
                break
                
            case .ActivateThumbnail:
                self.picture = try responseSerializer.process(activateThumbnailResponse: task.response, url: url, error: error)
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
    
    @objc override public func taskDidComplete(sessionManager: AFURLSessionManager, task: URLSessionTask, error: NSError?)
    {
        let setFinishedState = {
            self.currentTaskIdentifier = nil
            self.state = .finished
        }
        
        // 1. Perform any necessary file clean up based on the state that just completed
        if self.currentRequest == .UploadVideo
        {
            FileManager.default.deleteFile(at: self.videoUrl)
        }
        else if self.currentRequest == .UploadThumbnail
        {
            if let thumbnailUrl = self.thumbnailUrl {
                FileManager.default.deleteFile(at: thumbnailUrl)
            }
        }
        
        // 2. Check for errors and bail if necessary
        if self.error == nil
        {
            if let taskError = task.error // task.error is reserved for client-side errors, so check it first
            {
                let domain = self.errorDomain(for: self.currentRequest)
                self.error = (taskError as NSError).error(byAddingDomain: domain)
            }
            else if let error = error
            {
                let domain = self.errorDomain(for: self.currentRequest)
                self.error = error.error(byAddingDomain: domain)
            }
        }
        
        guard self.error == nil else
        {
            setFinishedState()
            return
        }
        
        // 3. Get the next state in the state machine
        let nextRequest = CAMUploadRequest.nextRequest(self.currentRequest)
        if nextRequest == nil
        {
            setFinishedState()
            return
        }
        
        // 4. Perform any necessary state transition checks
        if nextRequest == .CreateThumbnail && self.thumbnailUrl == nil
        {
            // 4.b If we're trying to transition to the Thumbnail Upload state and we don't have a thumbnail to upload,
            // there's no need to continue with the state machine, clean up and exit.
            setFinishedState()
            return
        }
        
        // 5. Transition to the next state and start the request
        do
        {
            let sessionManager = sessionManager as! VimeoSessionManager
            try self.transitionToState(request: nextRequest!, sessionManager: sessionManager)
            self.resume(sessionManager: sessionManager)
        }
        catch let error as NSError
        {
            self.error = error
            setFinishedState()
        }
    }
    
    // MARK: Private API
    
    private func transitionToState(request: CAMUploadRequest, sessionManager: VimeoSessionManager) throws
    {
        self.currentRequest = request
        let task = try self.taskForRequest(request: request, sessionManager: sessionManager)
        self.currentTaskIdentifier = task.taskIdentifier
    }
    
    private func taskForRequest(request: CAMUploadRequest, sessionManager: VimeoSessionManager) throws -> URLSessionTask
    {
        switch request
        {
        case .CreateVideo:
            return try sessionManager.createVideoDownloadTask(url: self.videoUrl, videoSettings: self.videoSettings, uploadParameters: VimeoSessionManager.Constants.DefaultUploadParameters)
        case .UploadVideo:
            guard let uploadUri = self.uploadTicket?.uploadLinkSecure else
            {
                throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }
            
            return try sessionManager.uploadVideoTask(source: self.videoUrl, destination: uploadUri, completionHandler: nil)
            
        case .CreateThumbnail:
            guard let videoUri = self.uploadTicket?.video?.uri else
            {
                throw NSError(domain: UploadErrorDomain.CreateThumbnail.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to create thumbnail resource, but videoUri is nil"])
            }
            
            return try sessionManager.createThumbnailDownloadTask(uri: videoUri)
            
        case .UploadThumbnail:
            guard let thumbnailUploadLink = self.pictureTicket?.link, let thumbnailUrl = self.thumbnailUrl else
            {
                throw NSError(domain: UploadErrorDomain.UploadThumbnail.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate thumbnail upload, but thumbnailUploadLink is nil"])
            }
            
            return try sessionManager.uploadThumbnailTask(source: thumbnailUrl as URL, destination: thumbnailUploadLink, completionHandler: nil)
            
        case .ActivateThumbnail:
            guard let thumbnailUri = self.pictureTicket?.uri else
            {
                throw NSError(domain: UploadErrorDomain.ActivateThumbnail.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to activate thumbnail, but thumbnailUri is nil"])
            }
            
            return try sessionManager.activateThumbnailTask(activationUri: thumbnailUri)
        }
    }
    
    private func errorDomain(for request: CAMUploadRequest) -> String
    {
        switch request
        {
        case .CreateVideo:
            return UploadErrorDomain.Create.rawValue
        case .UploadVideo:
            return UploadErrorDomain.Upload.rawValue
        case .CreateThumbnail:
            return UploadErrorDomain.CreateThumbnail.rawValue
        case .UploadThumbnail:
            return UploadErrorDomain.UploadThumbnail.rawValue
        case .ActivateThumbnail:
            return UploadErrorDomain.ActivateThumbnail.rawValue
        }
    }
    
    //MARK: NSCoding
    
    @objc required public init(coder aDecoder: NSCoder)
    {
        self.videoUrl = aDecoder.decodeObject(forKey: ArchiverConstants.VideoUrlKey) as! URL
        self.thumbnailUrl = aDecoder.decodeObject(forKey: ArchiverConstants.ThumbnailUrlKey) as? URL
        self.videoSettings = aDecoder.decodeObject(forKey: ArchiverConstants.VideoSettingsKey) as? VideoSettings
        self.uploadTicket = aDecoder.decodeObject(forKey: ArchiverConstants.UploadTicketKey) as? VIMUploadTicket
        self.currentRequest = CAMUploadRequest(rawValue: aDecoder.decodeObject(forKey: ArchiverConstants.CurrentRequestKey) as! String)!
        
        super.init(coder: aDecoder)
    }
    
    @objc override public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.videoUrl, forKey: ArchiverConstants.VideoUrlKey)
        aCoder.encode(self.thumbnailUrl, forKey: ArchiverConstants.ThumbnailUrlKey)
        aCoder.encode(self.videoSettings, forKey: ArchiverConstants.VideoSettingsKey)
        aCoder.encode(self.uploadTicket, forKey: ArchiverConstants.UploadTicketKey)
        aCoder.encode(self.currentRequest.rawValue, forKey: ArchiverConstants.CurrentRequestKey)
        
        super.encode(with: aCoder)
    }
}

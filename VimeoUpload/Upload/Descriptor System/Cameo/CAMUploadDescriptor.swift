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

public class CAMUploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    let videoUrl: NSURL
    let videoSettings: VideoSettings?
    let thumbnailUrl: NSURL?
    
    public private(set) var uploadTicket: VIMUploadTicket?
    private(set) var pictureTicket: VIMThumbnailUploadTicket?
    private(set) var picture: VIMPicture?
    
    private (set) var currentRequest = CAMUploadRequest.CreateVideo
    {
        didSet
        {
            print("\(self.currentRequest.rawValue) \(self.identifier)")
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
    
    public var type: VideoDescriptorType
    {
        return .Upload
    }
    
    public var videoUri: VideoUri?
    
    public var progressDescriptor: ProgressDescriptor
    {
        return self
    }
    
    //MARK: Initializers
    
    required public init()
    {
        fatalError("default init() should not be used, use init(videoUrl:videoSettings:thumbnailUrl:) instead")
    }
    
    public init(videoUrl: NSURL, videoSettings: VideoSettings? = nil, thumbnailUrl: NSURL?)
    {
        self.videoUrl = videoUrl
        self.videoSettings = videoSettings
        self.thumbnailUrl = thumbnailUrl
        
        super.init()
    }
    
    //MARK: Overrides
    
    override public func prepare(sessionManager sessionManager: AFURLSessionManager) throws
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
            self.state = .Finished
            
            throw error
        }
    }
    
    override public func resume(sessionManager sessionManager: AFURLSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
        if let identifier = self.currentTaskIdentifier, let task = sessionManager.uploadTaskForIdentifier(identifier), let progress = sessionManager.uploadProgressForTask(task)
        {
            self.progress = progress
        }
    }
    
    override public func cancel(sessionManager sessionManager: AFURLSessionManager)
    {
        super.cancel(sessionManager: sessionManager)
        
        NSFileManager.defaultManager().deleteFileAtURL(self.videoUrl)
        
        if let thumbnailUrl = self.thumbnailUrl {
            NSFileManager.defaultManager().deleteFileAtURL(thumbnailUrl)
        }
    }
    
    override public func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier, let task = sessionManager.uploadTaskForIdentifier(identifier), let progress = sessionManager.uploadProgressForTask(task) else
        {
            NSFileManager.defaultManager().deleteFileAtURL(self.videoUrl)
            
            if let thumbnailUrl = self.thumbnailUrl {
                NSFileManager.defaultManager().deleteFileAtURL(thumbnailUrl)
            }
            
            let error = NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
            self.error = error // TODO: Whenever we set error delete local file? Same for download?
            self.currentTaskIdentifier = nil
            self.state = .Finished
            
            throw error
        }
        
        self.progress = progress
    }
    
    override public func taskDidFinishDownloading(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
    {
        let sessionManager = sessionManager as! VimeoSessionManager
        let responseSerializer = sessionManager.responseSerializer as! VimeoResponseSerializer
        
        do
        {
            switch self.currentRequest
            {
            case .CreateVideo:
                self.uploadTicket = try responseSerializer.processCreateVideoResponse(task.response, url: url, error: error)
                
            case .UploadVideo:
                break
                
            case .CreateThumbnail:
                self.pictureTicket = try responseSerializer.processCreateThumbnailResponse(task.response, url: url, error: error)
                
            case .UploadThumbnail:
                break
                
            case .ActivateThumbnail:
                self.picture = try responseSerializer.processActivateThumbnailResponse(task.response, url: url, error: error)
            }
        }
        catch let error as NSError
        {
            self.error = error
            self.currentTaskIdentifier = nil
            self.state = .Finished
        }
        
        return nil
    }
    
    override public func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        let setFinishedState = {
            self.currentTaskIdentifier = nil
            self.state = .Finished
        }
        
        // 1. Perform any necessary file clean up based on the state that just completed
        if self.currentRequest == .UploadVideo
        {
            NSFileManager.defaultManager().deleteFileAtURL(self.videoUrl)
        }
        else if self.currentRequest == .UploadThumbnail
        {
            if let thumbnailUrl = self.thumbnailUrl {
                NSFileManager.defaultManager().deleteFileAtURL(thumbnailUrl)
            }
        }
        
        // 2. Check for errors and bail if necessary
        if self.error == nil
        {
            if let taskError = task.error // task.error is reserved for client-side errors, so check it first
            {
                let domain = self.errorDomainForRequest(self.currentRequest)
                self.error = taskError.errorByAddingDomain(domain)
            }
            else if let error = error
            {
                let domain = self.errorDomainForRequest(self.currentRequest)
                self.error = error.errorByAddingDomain(domain)
            }
        }
        
        guard self.error == nil else
        {
            setFinishedState()
            return
        }
        
        // 3. Get the next state in the state machine
        var nextRequest = CAMUploadRequest.nextRequest(self.currentRequest)
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
    
    private func transitionToState(request request: CAMUploadRequest, sessionManager: VimeoSessionManager) throws
    {
        self.currentRequest = request
        let task = try self.taskForRequest(request: request, sessionManager: sessionManager)
        self.currentTaskIdentifier = task.taskIdentifier
    }
    
    private func taskForRequest(request request: CAMUploadRequest, sessionManager: VimeoSessionManager) throws -> NSURLSessionTask
    {
        switch request
        {
        case .CreateVideo:
            return try sessionManager.createVideoDownloadTask(url: self.videoUrl, videoSettings: self.videoSettings)
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
            guard let thumbnailUploadLink = self.pictureTicket?.link, thumbnailUrl = self.thumbnailUrl else
            {
                throw NSError(domain: UploadErrorDomain.UploadThumbnail.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate thumbnail upload, but thumbnailUploadLink is nil"])
            }
            
            return try sessionManager.uploadThumbnailTask(source: thumbnailUrl, destination: thumbnailUploadLink, completionHandler: nil)
            
        case .ActivateThumbnail:
            guard let thumbnailUri = self.pictureTicket?.uri else
            {
                throw NSError(domain: UploadErrorDomain.ActivateThumbnail.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to activate thumbnail, but thumbnailUri is nil"])
            }
            
            return try sessionManager.activateThumbnailTask(activationUri: thumbnailUri)
        }
    }
    
    private func errorDomainForRequest(request: CAMUploadRequest) -> String
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
        
        return ""
    }
    
    //MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder)
    {
        self.videoUrl = aDecoder.decodeObjectForKey(ArchiverConstants.VideoUrlKey) as! NSURL
        self.thumbnailUrl = aDecoder.decodeObjectForKey(ArchiverConstants.ThumbnailUrlKey) as? NSURL
        self.videoSettings = aDecoder.decodeObjectForKey(ArchiverConstants.VideoSettingsKey) as? VideoSettings
        self.uploadTicket = aDecoder.decodeObjectForKey(ArchiverConstants.UploadTicketKey) as? VIMUploadTicket
        self.currentRequest = CAMUploadRequest(rawValue: aDecoder.decodeObjectForKey(ArchiverConstants.CurrentRequestKey) as! String)!
        
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.videoUrl, forKey: ArchiverConstants.VideoUrlKey)
        aCoder.encodeObject(self.thumbnailUrl, forKey: ArchiverConstants.ThumbnailUrlKey)
        aCoder.encodeObject(self.videoSettings, forKey: ArchiverConstants.VideoSettingsKey)
        aCoder.encodeObject(self.uploadTicket, forKey: ArchiverConstants.UploadTicketKey)
        aCoder.encodeObject(self.currentRequest.rawValue, forKey: ArchiverConstants.CurrentRequestKey)
        
        super.encodeWithCoder(aCoder)
    }
}

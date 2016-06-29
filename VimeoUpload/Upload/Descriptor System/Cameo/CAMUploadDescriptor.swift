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

//TODO: Once this class is moved into VimeoUpload, we can remove this import.  [MW] 6/27/16
import VimeoUpload

public class CAMUploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    let videoUrl: NSURL
    let videoSettings: VideoSettings?
    let thumbnailFileUrl: NSURL?
    
    private(set) var uploadTicket: VIMUploadTicket?
    private(set) var video: VIMVideo?
    private(set) var thumbnailTicket: VIMThumbnailUploadTicket?
    private(set) var thumbnail: VIMPicture?
    
    private (set) var currentRequest = CAMUploadRequest.CreateVideo
    {
        didSet
        {
            print("\(self.currentRequest.rawValue) \(self.identifier)")
        }
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
    
    public init(videoUrl: NSURL, videoSettings: VideoSettings? = nil, thumbnailFileUrl: NSURL?)
    {
        self.videoUrl = videoUrl
        self.videoSettings = videoSettings
        self.thumbnailFileUrl = thumbnailFileUrl
        
        super.init()
    }
    
    //MARK: Overrides
    
    override func prepare(sessionManager sessionManager: AFURLSessionManager) throws
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
    
    //TODO: need to figure out how this method changes to include the thumbnail upload [MW] 6/27/16
    override func resume(sessionManager sessionManager: AFURLSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
        if let identifier = self.currentTaskIdentifier,
            task = sessionManager.uploadTaskForIdentifier(identifier),
            progress = sessionManager.uploadProgressForTask(task)
        {
            self.progress = progress
        }
    }
    
    override func cancel(sessionManager sessionManager: AFURLSessionManager)
    {
        super.cancel(sessionManager: sessionManager)
        
        NSFileManager.defaultManager().deleteFileAtURL(self.videoUrl)
        
        if let thumbnailFileUrl = self.thumbnailFileUrl {
            NSFileManager.defaultManager().deleteFileAtURL(thumbnailFileUrl)
        }
    }
    
    //TODO: need to figure out how this method changes to include the thumbnail upload [MW] 6/27/16
    override func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier,
            task = sessionManager.uploadTaskForIdentifier(identifier),
            progress = sessionManager.uploadProgressForTask(task) else
        {
            NSFileManager.defaultManager().deleteFileAtURL(self.videoUrl)
            
            if let thumbnailFileUrl = self.thumbnailFileUrl {
                NSFileManager.defaultManager().deleteFileAtURL(thumbnailFileUrl)
            }
            
            let error = NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
            self.error = error // TODO: Whenever we set error delete local file? Same for download?
            self.currentTaskIdentifier = nil
            self.state = .Finished
            
            throw error
        }
        
        self.progress = progress
    }
    
    override func taskDidFinishDownloading(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
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
                
            case .ActivateVideo:
                self.videoUri = try responseSerializer.processActivateVideoResponse(task.response, url: url, error: error)
                
            case .VideoSettings:
                self.video = try responseSerializer.processVideoSettingsResponse(task.response, url: url, error: error)
                
            case .CreateThumbnail:
                self.thumbnailTicket = try responseSerializer.processCreateThumbnailResponse(task.response, url: url, error: error)
                
            case .UploadThumbnail:
                break
                
            case .ActivateThumbnail:
                self.thumbnail = try responseSerializer.processActivateThumbnailResponse(task.response, url: url, error: error)
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
    
    //TODO: need to figure out how this method changes to include the thumbnail upload [MW] 6/27/16
    override func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        if self.currentRequest == .UploadVideo
        {
            NSFileManager.defaultManager().deleteFileAtURL(self.videoUrl)
        }
        else if self.currentRequest == .UploadThumbnail
        {
            if let thumbnailFileUrl = self.thumbnailFileUrl {
                NSFileManager.defaultManager().deleteFileAtURL(thumbnailFileUrl)
            }
        }
        
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
        
        var nextRequest = CAMUploadRequest.nextRequest(self.currentRequest)
        if self.error != nil || nextRequest == nil
        {
            self.currentTaskIdentifier = nil
            self.state = .Finished
            
            return
        }
        else if nextRequest == .VideoSettings && self.videoSettings == nil
        {
            nextRequest = CAMUploadRequest.nextRequest(nextRequest!)
            if nextRequest == nil
            {
                self.currentTaskIdentifier = nil
                self.state = .Finished
                
                return
            }
        }
        else if nextRequest == .CreateThumbnail && self.thumbnailFileUrl == nil
        {
            self.currentTaskIdentifier = nil
            self.state = .Finished
            
            return
        }
        
        do
        {
            let sessionManager = sessionManager as! VimeoSessionManager
            try self.transitionToState(request: nextRequest!, sessionManager: sessionManager)
            self.resume(sessionManager: sessionManager)
        }
        catch let error as NSError
        {
            self.error = error
            self.currentTaskIdentifier = nil
            self.state = .Finished
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
            return try sessionManager.createVideoDownloadTask(url: self.videoUrl)
        case .UploadVideo:
            guard let uploadUri = self.uploadTicket?.uploadLinkSecure else
            {
                throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }
            
            return try sessionManager.uploadVideoTask(source: self.videoUrl, destination: uploadUri, progress: &self.progress, completionHandler: nil)
            
        case .ActivateVideo:
            guard let activationUri = self.uploadTicket?.completeUri else
            {
                throw NSError(domain: UploadErrorDomain.Activate.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Activate response did not contain the required values."])
            }
            
            return try sessionManager.activateVideoDownloadTask(uri: activationUri)
            
        case .VideoSettings:
            guard let videoUri = self.videoUri, let videoSettings = self.videoSettings else
            {
                throw NSError(domain: UploadErrorDomain.VideoSettings.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Video settings response did not contain the required values."])
            }
            
            return try sessionManager.videoSettingsDownloadTask(videoUri: videoUri, videoSettings: videoSettings)
            
        case .CreateThumbnail:
            guard let videoUri = self.videoUri else
            {
                throw NSError(domain: "CreateVideoThumbnailErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to create thumbnail resource, but videoUri is nil"])
            }
            
            return try sessionManager.createThumbnailDownloadTask(uri: videoUri)
            
        case .UploadThumbnail:
            guard let thumbnailUploadLink = self.thumbnailTicket?.link, thumbnailFileUrl = self.thumbnailFileUrl else
            {
                throw NSError(domain: "UploadVideoThumbnailErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate thumbnail upload, but thumbnailUploadLink is nil"])
            }
            
            return try sessionManager.uploadThumbnailTask(source: thumbnailFileUrl, destination: thumbnailUploadLink, progress: &self.progress, completionHandler: nil)
            
        case .ActivateThumbnail:
            guard let thumbnailUri = self.thumbnailTicket?.uri else
            {
                throw NSError(domain: "ActivateVideoThumbnailErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to activate thumbnail, but thumbnailUri is nil"])
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
        case .ActivateVideo:
            return UploadErrorDomain.Activate.rawValue
        case .VideoSettings:
            return UploadErrorDomain.VideoSettings.rawValue
        case .CreateThumbnail:
            break
        case .UploadThumbnail:
            break
        case .ActivateThumbnail:
            break
        }
        
        return ""
    }
    
    //MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder)
    {
        self.videoUrl = aDecoder.decodeObjectForKey("videoUrl") as! NSURL
        self.thumbnailFileUrl = aDecoder.decodeObjectForKey("thumbnailFileUrl") as? NSURL
        self.videoSettings = aDecoder.decodeObjectForKey("videoSettings") as? VideoSettings
        self.uploadTicket = aDecoder.decodeObjectForKey("uploadTicket") as? VIMUploadTicket
        self.currentRequest = CAMUploadRequest(rawValue: aDecoder.decodeObjectForKey("currentRequest") as! String)!
        
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.videoUrl, forKey: "videoUrl")
        aCoder.encodeObject(self.thumbnailFileUrl, forKey: "thumbnailFileUrl")
        aCoder.encodeObject(self.videoSettings, forKey: "videoSettings")
        aCoder.encodeObject(self.uploadTicket, forKey: "uploadTicket")
        aCoder.encodeObject(self.currentRequest.rawValue, forKey: "currentRequest")
        
        super.encodeWithCoder(aCoder)
    }
}

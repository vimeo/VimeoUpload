//
//  CAMUploadDescriptor.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/27/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking

//TODO: Once this class is moved into VimeoUpload, we can remove this import.  [MW] 6/27/16
import VimeoUpload

public class CAMUploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    let videoUrl: NSURL
    let videoSettings: VideoSettings?
    let thumbnailUrl: NSURL
    
    private(set) var uploadTicket: VIMUploadTicket?
    private(set) var video: VIMVideo?
    
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
    {
        return self.uploadTicket?.video?.uri
    }
    
    public var progressDescriptor: ProgressDescriptor
    {
        return self
    }
    
    //MARK: Initializers
    
    required public init()
    {
        fatalError("default init() should not be used, use init(videoUrl:videoSettings:thumbnailUrl:) instead")
    }
    
    public init(videoUrl: NSURL, videoSettings: VideoSettings? = nil, thumbnailUrl: NSURL)
    {
        self.videoUrl = videoUrl
        self.videoSettings = videoSettings
        self.thumbnailUrl = thumbnailUrl
        
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
                throw NSError(domain: UploadErrorDomain.Activate.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }
            
            return try sessionManager.UploadVideoTask(source: self.videoUrl, destination: uploadUri, progress: &self.progress, completionHandler: nil)
        case .ActivateVideo:
            break
        case .CreateThumbnail:
            break
        case .UploadThumbnail:
            break
        case .ActivateThumbnail:
            break
        }
    }
    
    //MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder)
    {
        self.videoUrl = aDecoder.decodeObjectForKey("videoUrl") as! NSURL
        self.thumbnailUrl = aDecoder.decodeObjectForKey("thumbnailUrl") as! NSURL
        self.videoSettings = aDecoder.decodeObjectForKey("videoSettings") as? VideoSettings
        self.uploadTicket = aDecoder.decodeObjectForKey("uploadTicket") as? VIMUploadTicket
        self.currentRequest = CAMUploadRequest(rawValue: aDecoder.decodeObjectForKey("currentRequest") as! String)!
        
        super.init(coder: aDecoder)
    }
    
    override public func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.videoUrl, forKey: "videoUrl")
        aCoder.encodeObject(self.thumbnailUrl, forKey: "thumbnailUrl")
        aCoder.encodeObject(self.videoSettings, forKey: "videoSettings")
        aCoder.encodeObject(self.uploadTicket, forKey: "uploadTicket")
        aCoder.encodeObject(self.currentRequest.rawValue, forKey: "currentRequest")
        
        super.encodeWithCoder(aCoder)
    }
}

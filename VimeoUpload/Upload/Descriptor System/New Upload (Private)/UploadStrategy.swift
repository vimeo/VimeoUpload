//
//  UploadStrategy.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 11/13/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking

open class UploadStrategy: NSObject, NSSecureCoding
{
    public static var supportsSecureCoding: Bool = true
    
    public override init()
    {
        
    }
    
    public func encode(with aCoder: NSCoder)
    {
        
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        
    }
    
    open func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    {
        fatalError("Error: Must override this method.")
    }
    
    internal func uploadLink(from video: VIMVideo) -> String?
    {
        fatalError("Error: Must override this method.")
    }
}

public class StreamingUploadStrategy: UploadStrategy
{
    override public func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    {
        let task = try sessionManager.uploadVideoTask(source: fileUrl, destination: uploadLink, completionHandler: nil)
        
        return task
    }
    
    override public func uploadLink(from video: VIMVideo) -> String?
    {
        return video.upload?.uploadLink
    }
}

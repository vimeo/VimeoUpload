//
//  UploadTaskBuilder.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 11/13/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking

open class UploadTaskBuilder: NSObject, NSCoding
{
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
}

public class StreamingUploadTaskBuilder: UploadTaskBuilder
{
    override public func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    {
        let task = try sessionManager.uploadVideoTask(source: fileUrl, destination: uploadLink, completionHandler: nil)
        
        return task
    }
}

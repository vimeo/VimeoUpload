//
//  UploadTaskBuilder.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 11/13/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking

open class UploadTaskBuilder
{
    func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    {
        fatalError("Error: Must override this method.")
    }
}

final class StreamingUploadTaskBuilder: UploadTaskBuilder
{
    override func makeUploadTask(sessionManager: VimeoSessionManager, fileUrl: URL, uploadLink: String) throws -> URLSessionUploadTask
    {
        let task = try sessionManager.uploadVideoTask(source: fileUrl, destination: uploadLink, completionHandler: nil)
        
        return task
    }
}

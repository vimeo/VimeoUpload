//
//  AFURLSessionManager+Upload.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 2/2/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

extension AFURLSessionManager
{
    func uploadTaskForIdentifier(identifier: Int) -> NSURLSessionUploadTask?
    {
        return self.uploadTasks.filter{ $0.taskIdentifier == identifier }.first as? NSURLSessionUploadTask
    }
}
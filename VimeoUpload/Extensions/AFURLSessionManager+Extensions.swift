//
//  AFURLSessionManager+Extensions.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 12/7/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

extension AFURLSessionManager
{
    func taskForIdentifier(identifier: Int) -> NSURLSessionTask?
    {
        return self.tasks.filter{ $0.taskIdentifier == identifier }.first as? NSURLSessionTask
    }
}

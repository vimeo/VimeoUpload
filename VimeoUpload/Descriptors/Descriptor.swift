//
//  Descriptor.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/20/15.
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

enum State: String
{
    case Ready = "Ready"
    case Executing = "Executing"
    case Finished = "Finished"
}

class Descriptor: NSObject
{
    static let ErrorDomain = "DescriptorErrorDomain"
    
    var state = State.Ready
    var identifier: String?
    var error: NSError?
    var currentTaskIdentifier: Int?

    override init()
    {
        
    }
    
    // MARK: Subclass Overrides

    func start(sessionManager: AFURLSessionManager) throws
    {
        if self.state != .Ready
        {
            throw NSError(domain: Descriptor.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot start a descriptor that is note in the .Ready state"])
        }
        
        if let _ = self.error
        {
            throw NSError(domain: Descriptor.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot start a descriptor that has a pre-existing error"])
        }        
    }

    func cancel(sessionManager: AFURLSessionManager)
    {
        for task in sessionManager.tasks
        {
            if task.taskIdentifier == self.currentTaskIdentifier
            {
                task.cancel()
                break
            }
        }
    }

    func didLoadFromCache(sessionManager: AFURLSessionManager) throws
    {
        fatalError("didLoadFromCache(sessionManager:) has not been implemented")
    }
    
    func taskDidFinishDownloading(sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
    {
        fatalError("taskDidFinishDownloading(sessionManager:task:url:) has not been implemented")
    }

    func taskDidComplete(sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        fatalError("taskDidComplete(sessionManager:task:error:) has not been implemented")
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder)
    {
        self.state = State(rawValue: aDecoder.decodeObjectForKey("state") as! String)! // If force unwrap fails we have a big problem
        self.identifier = aDecoder.decodeObjectForKey("identifier") as? String
        self.error = aDecoder.decodeObjectForKey("error") as? NSError
        self.currentTaskIdentifier = aDecoder.decodeIntegerForKey("currentTaskIdentifier")
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.state.rawValue, forKey: "state")
        aCoder.encodeObject(self.identifier, forKey: "identifier")
        aCoder.encodeObject(self.error, forKey: "error")
        if let currentTaskIdentifier = self.currentTaskIdentifier
        {
            aCoder.encodeInteger(currentTaskIdentifier, forKey: "currentTaskIdentifier")
        }
    }
}

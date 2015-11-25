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

@objc protocol DescriptorProtocol
{
    func start(sessionManager sessionManager: AFURLSessionManager) throws
    func cancel(sessionManager sessionManager: AFURLSessionManager)
    func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    optional func taskDidFinishDownloading(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
    func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
}

enum State: String
{
    case Ready = "Ready"
    case Executing = "Executing"
    case Finished = "Finished"
}

class Descriptor: NSObject, DescriptorProtocol
{
    static let ErrorDomain = "DescriptorErrorDomain"
    
    // MARK: 
    
    dynamic private(set) var stateObservable: String = State.Ready.rawValue
    var state = State.Ready
    {
        didSet
        {
            self.stateObservable = state.rawValue
        }
    }
    
    // MARK:
    
    var identifier: String?
    var error: NSError?
    var currentTaskIdentifier: Int?

    // MARK:
    // MARK: Initialization

    override init()
    {
        
    }
    
    // MARK: Subclass Overrides

    func start(sessionManager sessionManager: AFURLSessionManager) throws
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

    func cancel(sessionManager sessionManager: AFURLSessionManager)
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

    func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    {
        fatalError("didLoadFromCache(sessionManager:) has not been implemented")
    }
    
    func taskDidFinishDownloading(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
    {
        return nil
    }

    func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
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

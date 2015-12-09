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
    func prepare(sessionManager sessionManager: AFURLSessionManager) throws
    func resume(sessionManager sessionManager: AFURLSessionManager)
    func suspend(sessionManager sessionManager: AFURLSessionManager)
    func cancel(sessionManager sessionManager: AFURLSessionManager)
    func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager)
    optional func taskDidFinishDownloading(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
    func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
}

enum State: String
{
    case Ready = "Ready"
    case Executing = "Executing"
    case Suspended = "Suspended"
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

    func prepare(sessionManager sessionManager: AFURLSessionManager) throws
    {
        fatalError("prepare(sessionManager:) has not been implemented")
    }

    func resume(sessionManager sessionManager: AFURLSessionManager)
    {
        self.state = .Executing
        
        if let identifier = self.currentTaskIdentifier, let task = sessionManager.taskForIdentifier(identifier)
        {
            task.resume()
        }
    }
    
    func suspend(sessionManager sessionManager: AFURLSessionManager)
    {
        self.state = .Suspended

        if let identifier = self.currentTaskIdentifier, let task = sessionManager.taskForIdentifier(identifier)
        {
            task.suspend()
        }
    }

    func cancel(sessionManager sessionManager: AFURLSessionManager)
    {
        if let identifier = self.currentTaskIdentifier, let task = sessionManager.taskForIdentifier(identifier)
        {
            task.cancel()
        }
    }

    func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager)
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

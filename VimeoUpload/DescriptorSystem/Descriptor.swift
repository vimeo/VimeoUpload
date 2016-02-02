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
    func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
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
    private static let StateCoderKey = "state"
    private static let IdentifierCoderKey = "identifier"
    private static let ErrorCoderKey = "error"
    private static let CurrentTaskIdentifierCoderKey = "currentTaskIdentifier"

    // MARK:
    
    dynamic private(set) var stateObservable: String = State.Ready.rawValue
    var state = State.Ready
    {
        didSet
        {
            self.stateObservable = state.rawValue
            
            if self.state == .Finished
            {
                self.currentTaskIdentifier = nil
            }
        }
    }
    
    // MARK:
    
    var identifier: String?
    var error: NSError?
    {
        didSet
        {
            if error != nil
            {
                self.state = .Finished
            }
        }
    }

    var currentTaskIdentifier: Int?

    // MARK: - Initialization

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
        
        if #available(iOS 8, *)
        {
            if let identifier = self.currentTaskIdentifier,
                let task = sessionManager.taskForIdentifier(identifier)
            {
                task.resume()
            }
        }
        else
        {
            if let identifier = self.currentTaskIdentifier,
                let task = sessionManager.taskForIdentifierWorkaround(identifier)
            {
                if let dataTask = task as? NSURLSessionDataTask
                {
                    dataTask.resume()
                }
                else if let uploadTask = task as? NSURLSessionUploadTask
                {
                    uploadTask.resume()
                }
                else if let downloadTask = task as? NSURLSessionDownloadTask
                {
                    downloadTask.resume()
                }
                else
                {
                    assertionFailure("Unable to cast task to proper class, therefore unable to resume")
                }
            }
        }
    }
    
    func suspend(sessionManager sessionManager: AFURLSessionManager)
    {
        self.state = .Suspended
        
        // Would be nice to call task.suspend(), but the task will start over from 0 (if you suspend it for long enough?),
        // but the server thinks that we're resuming from the last byte, no good. Instead we need to cancel and start over,
        // appending the Content-Range header [AH] 12/25/2015

        self.cancel(sessionManager: sessionManager)
    }

    func cancel(sessionManager sessionManager: AFURLSessionManager)
    {
        if #available(iOS 8, *)
        {
            if let identifier = self.currentTaskIdentifier,
                let task = sessionManager.taskForIdentifier(identifier)
            {
                task.cancel()
            }
        }
        else
        {
            if let identifier = self.currentTaskIdentifier,
                let task = sessionManager.taskForIdentifierWorkaround(identifier)
            {
                if let dataTask = task as? NSURLSessionDataTask
                {
                    dataTask.cancel()
                }
                else if let uploadTask = task as? NSURLSessionUploadTask
                {
                    uploadTask.cancel()
                }
                else if let downloadTask = task as? NSURLSessionDownloadTask
                {
                    downloadTask.cancel()
                }
                else
                {
                    assertionFailure("Unable to cast task to proper class, therefore unable to cancel")
                }
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
        self.state = State(rawValue: aDecoder.decodeObjectForKey(self.dynamicType.StateCoderKey) as! String)!
        self.identifier = aDecoder.decodeObjectForKey(self.dynamicType.IdentifierCoderKey) as? String
        self.error = aDecoder.decodeObjectForKey(self.dynamicType.ErrorCoderKey) as? NSError
        self.currentTaskIdentifier = aDecoder.decodeIntegerForKey(self.dynamicType.CurrentTaskIdentifierCoderKey)
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.state.rawValue, forKey: self.dynamicType.StateCoderKey)
        aCoder.encodeObject(self.identifier, forKey: self.dynamicType.IdentifierCoderKey)
        aCoder.encodeObject(self.error, forKey: self.dynamicType.ErrorCoderKey)
        if let currentTaskIdentifier = self.currentTaskIdentifier
        {
            aCoder.encodeInteger(currentTaskIdentifier, forKey: self.dynamicType.CurrentTaskIdentifierCoderKey)
        }
    }
}

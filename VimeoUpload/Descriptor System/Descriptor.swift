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
import AFNetworking

public enum DescriptorState: String
{
    case Ready = "Ready"
    case Executing = "Executing"
    case Suspended = "Suspended"
    case Finished = "Finished"
}

public class Descriptor: NSObject, NSCoding
{
    private static let StateCoderKey = "state"
    private static let IdentifierCoderKey = "identifier"
    private static let ErrorCoderKey = "error"
    private static let CurrentTaskIdentifierCoderKey = "currentTaskIdentifier"

    // MARK:
    
    dynamic private(set) var stateObservable: String = DescriptorState.Ready.rawValue
    public var state = DescriptorState.Ready
    {
        didSet
        {
            self.stateObservable = state.rawValue
        }
    }
    
    // MARK:
    
    public var identifier: String?
    public var currentTaskIdentifier: Int?
    public var error: NSError?
    
    var isCancelled = false
    
    // MARK: - Initialization

    required override public init()
    {
        super.init()
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
            // See note above taskForIdentifierWorkaround for details on why this is necessary (iOS7 bug) [AH] 2/5/2016
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
        let originalState = self.state
        
        self.state = .Suspended

        // If we're suspending a just-enqueued descriptor, don't cancel it, just update it's state to .Suspended [AH] 2/24/2016
        
        if originalState == .Ready
        {
            return
        }
        
        // Would be nice to call task.suspend(), but when you suspend and resume the task will start over from 0
        // (If you suspend it for long enough? The behavior is a little unpredictable here),
        // but the server thinks that we're resuming from the last byte, and we can't rewrite the headers, no good. 
        // Instead we need to cancel and start over, appending the Content-Range header [AH] 12/25/2015
        
        self.doCancel(sessionManager: sessionManager)
    }

    func cancel(sessionManager sessionManager: AFURLSessionManager)
    {
        self.isCancelled = true
        self.state = .Finished

        self.doCancel(sessionManager: sessionManager)
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
    
    // MARK: Private API
    
    // We need this method because we need to differentiate between suspend-initiated cancellations and user-initiated cancellations [AH] 2/17/2016

    private func doCancel(sessionManager sessionManager: AFURLSessionManager)
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
            // See note above taskForIdentifierWorkaround for details on why this is necessary (iOS7 bug) [AH] 2/5/2016
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
            }
        }
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder)
    {
        self.state = DescriptorState(rawValue: aDecoder.decodeObjectForKey(self.dynamicType.StateCoderKey) as! String)!
        self.identifier = aDecoder.decodeObjectForKey(self.dynamicType.IdentifierCoderKey) as? String
        self.error = aDecoder.decodeObjectForKey(self.dynamicType.ErrorCoderKey) as? NSError
        self.currentTaskIdentifier = aDecoder.decodeIntegerForKey(self.dynamicType.CurrentTaskIdentifierCoderKey)
    }
    
    public func encodeWithCoder(aCoder: NSCoder)
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

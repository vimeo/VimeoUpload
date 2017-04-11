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

open class Descriptor: NSObject, NSCoding
{
    private static let StateCoderKey = "state"
    private static let IdentifierCoderKey = "identifier"
    private static let ErrorCoderKey = "error"
    private static let CurrentTaskIdentifierCoderKey = "currentTaskIdentifier"

    // MARK:
    
    dynamic private(set) var stateObservable: String = DescriptorState.Ready.rawValue
    open var state = DescriptorState.Ready
    {
        didSet
        {
            self.stateObservable = state.rawValue
        }
    }
    
    // MARK:
    
    open var identifier: String?
    open var currentTaskIdentifier: Int?
    open var error: NSError?
    
    private(set) open var isCancelled = false
    
    // MARK: - Initialization

    required override public init()
    {
        super.init()
    }
    
    // MARK: Subclass Overrides

    open func prepare(sessionManager: AFURLSessionManager) throws
    {
        fatalError("prepare(sessionManager:) has not been implemented")
    }

    open func resume(sessionManager: AFURLSessionManager)
    {
        self.state = .Executing
        
        if let identifier = self.currentTaskIdentifier,
            let task = sessionManager.task(for: identifier)
        {
            task.resume()
        }
    }
    
    open func suspend(sessionManager: AFURLSessionManager)
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

    open func cancel(sessionManager: AFURLSessionManager)
    {
        self.isCancelled = true
        self.state = .Finished

        self.doCancel(sessionManager: sessionManager)
    }
    
    open func didLoadFromCache(sessionManager: AFURLSessionManager) throws
    {
        fatalError("didLoadFromCache(sessionManager:) has not been implemented")
    }
    
    open func taskDidFinishDownloading(sessionManager: AFURLSessionManager, task: URLSessionDownloadTask, url: URL) -> URL?
    {
        return nil
    }

    open func taskDidComplete(sessionManager: AFURLSessionManager, task: URLSessionTask, error: NSError?)
    {
        fatalError("taskDidComplete(sessionManager:task:error:) has not been implemented")
    }
    
    // MARK: Private API
    
    // We need this method because we need to differentiate between suspend-initiated cancellations and user-initiated cancellations [AH] 2/17/2016

    private func doCancel(sessionManager: AFURLSessionManager)
    {
        if let identifier = self.currentTaskIdentifier,
            let task = sessionManager.task(for: identifier)
        {
            task.cancel()
        }
    }
    
    // MARK: NSCoding
    
    required public init(coder aDecoder: NSCoder)
    {
        self.state = DescriptorState(rawValue: aDecoder.decodeObject(forKey: type(of: self).StateCoderKey) as! String)!
        self.identifier = aDecoder.decodeObject(forKey: type(of: self).IdentifierCoderKey) as? String
        self.error = aDecoder.decodeObject(forKey: type(of: self).ErrorCoderKey) as? NSError
        self.currentTaskIdentifier = aDecoder.decodeInteger(forKey: type(of: self).CurrentTaskIdentifierCoderKey)
    }
    
    open func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.state.rawValue, forKey: type(of: self).StateCoderKey)
        aCoder.encode(self.identifier, forKey: type(of: self).IdentifierCoderKey)
        aCoder.encode(self.error, forKey: type(of: self).ErrorCoderKey)
        if let currentTaskIdentifier = self.currentTaskIdentifier
        {
            aCoder.encode(currentTaskIdentifier, forKey: type(of: self).CurrentTaskIdentifierCoderKey)
        }
    }
}

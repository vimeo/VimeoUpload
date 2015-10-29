//
//  Descriptor.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/20/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AFNetworking

enum State: String
{
    case Ready = "Ready"
    case Executing = "Executing"
    case Complete = "Complete"
}

class Descriptor: NSObject
{
    var state = State.Ready
    var identifier: String?
    var error: NSError?
    var currentTaskIdentifier: Int? // TODO: Convert this into a set?

    override init()
    {
        
    }
    
    // MARK: Subclass Overrides

    func start(sessionManager: AFURLSessionManager)
    {
        fatalError("start(sessionManager:) has not been implemented")
    }

    func cancel(sessionManager: AFURLSessionManager)
    {
        fatalError("cancel(sessionManager:) has not been implemented")
    }

    func didLoadFromCache(sessionManager: AFURLSessionManager)
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

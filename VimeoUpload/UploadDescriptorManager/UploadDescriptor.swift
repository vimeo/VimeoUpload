//
//  UploadDescriptor.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/18/15.
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

enum Request: String
{
    case Create = "Create"
    case Upload = "Upload"
    case Activate = "Activate"
    case Settings = "Settings"
    
    static func orderedRequests() -> [Request]
    {
        return [.Create, .Upload, .Activate, .Settings]
    }
    
    static func nextRequest(currentRequest: Request) -> Request?
    {
        let orderedRequests = Request.orderedRequests()
        if let index = orderedRequests.indexOf(currentRequest) where index + 1 < orderedRequests.count
        {
            return orderedRequests[index + 1]
        }
        
        return nil
    }
}

class UploadDescriptor: Descriptor
{    
    let url: NSURL
    let videoSettings: VideoSettings?
    
    private(set) var createVideoResponse: CreateVideoResponse?
    private(set) var videoUri: String?
    
    private static let ProgressKeyPath = "fractionCompleted"
    private var progressKVOContext = UInt8()
    private var isObserving = false
    private var uploadProgressObject: NSProgress?
    private(set) dynamic var uploadProgress: Double = 0 // KVO on this property

    private(set) var currentRequest = Request.Create
    {
        didSet
        {
            print(self.currentRequest.rawValue)
        }
    }

    override var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                print(self.error!.localizedDescription)
                self.state = .Complete
            }
        }
    }
    
    // MARK: Initialization

    deinit
    {
        self.removeObserverIfNecessary()
    }
    
    convenience init(url: NSURL)
    {
        self.init(url: url, videoSettings: nil)
    }

    init(url: NSURL, videoSettings: VideoSettings?)
    {
        self.url = url
        self.videoSettings = videoSettings
    
        super.init()
    }

    // MARK: Overrides
    
    // Start the first request and update the state accordingly

    override func start(sessionManager: AFURLSessionManager)
    {
        guard let sessionManager = sessionManager as? VimeoSessionManager else
        {
            fatalError("sessionManager must be of type VimeoSessionManager")
        }

        self.state = .Executing
        self.currentRequest = .Create

        do
        {
            let task = try sessionManager.createVideoDownloadTask(url: self.url, destination: nil, completionHandler: nil)
            self.currentTaskIdentifier = task.taskIdentifier
            task.resume()
        }
        catch let error as NSError
        {
            self.error = error // TODO: do something with this error (desc mgr will need to remove desc from list)
        }
    }

    override func cancel(sessionManager: AFURLSessionManager)
    {
        fatalError("cancel(sessionManager:) has not been implemented")
    }

    // If necessary, resume the current task and re-connect progress objects

    override func didLoadFromCache(sessionManager: AFURLSessionManager)
    {
        // TODO: restart tasks
        
        let results = sessionManager.uploadTasks.filter( { ($0 as! NSURLSessionUploadTask).taskIdentifier == self.currentTaskIdentifier } )
        
        assert(results.count < 2, "Upon reconnecting upload tasks with descriptors, found 2 tasks with same identifier")
        
        if results.count == 1
        {
            let task  = results.first as! NSURLSessionUploadTask
            self.uploadProgressObject = sessionManager.uploadProgressForTask(task)
            self.addObserver()
        }
    }

    override func taskDidFinishDownloading(sessionManager: AFURLSessionManager, task: NSURLSessionDownloadTask, url: NSURL) -> NSURL?
    {
        guard let sessionManager = sessionManager as? VimeoSessionManager else
        {
            fatalError("sessionManager must be of type VimeoSessionManager")
        }
        
        // TODO: check for Vimeo error here?
        
        switch self.currentRequest
        {
        case .Create:
            do
            {
                self.createVideoResponse = try (sessionManager.responseSerializer as! VimeoResponseSerializer).processCreateVideoResponse(task.response, url: url, error: error)
            }
            catch let error as NSError
            {
                self.error = error
            }
            
        case .Upload:
            print("Do nothing")
            
        case .Activate:
            do
            {
                self.videoUri = try (sessionManager.responseSerializer as! VimeoResponseSerializer).processActivateVideoResponse(task.response, url: url, error: error)
            }
            catch let error as NSError
            {
                self.error = error
            }

        case .Settings:
            print("To do")
            // TODO: fill in settings response handling
        }

        return nil
    }
    
    override func taskDidComplete(sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        guard let sessionManager = sessionManager as? VimeoSessionManager else
        {
            fatalError("sessionManager must be of type VimeoSessionManager")
        }

        if self.currentRequest == .Upload
        {
            self.cleanupAfterUpload()
        }

        // task.error is reserved for client-side errors, so check it first
        if let taskError = task.error where self.error == nil
        {
            self.error = taskError // TODO: add proper vimeo domain
        }

        if let error = error where self.error == nil
        {
            self.error = error // TODO: add proper vimeo domain
        }
        
        // The process is complete if there is an error,
        // If there's no next request,
        // Or if the next request is "settings" and there are no settings to apply.
        
        let nextRequest = Request.nextRequest(self.currentRequest)
        
        if self.error != nil || nextRequest == nil || (nextRequest == .Settings && self.videoSettings == nil)
        {
            self.currentTaskIdentifier = nil
            self.state = .Complete

            return
        }
        
        self.currentRequest = nextRequest!
        
        switch self.currentRequest
        {
        case .Create:
            print("Do nothing")
            
        case .Upload:
            guard let uploadUri = self.createVideoResponse?.uploadUri else
            {
                self.error = NSError.createResponseWithoutUploadUriError()

                return
            }
            
            do
            {
                let task = try sessionManager.uploadVideoTask(self.url, destination: uploadUri, progress: &self.uploadProgressObject, completionHandler: nil)
                self.addObserver()
                self.currentTaskIdentifier = task.taskIdentifier
                task.resume()
            }
            catch let error as NSError
            {
                self.error = error
            }
            
        case .Activate:
            guard let activationUri = self.createVideoResponse?.activationUri else
            {
                self.error = NSError.createResponseWithoutActivateUriError()
                
                return
            }
            
            do
            {
                let task = try sessionManager.activateVideoTask(activationUri, destination: nil, completionHandler: nil)
                self.currentTaskIdentifier = task.taskIdentifier
                task.resume()
            }
            catch let error as NSError
            {
                self.error = error
            }
            
        case .Settings:
            guard let videoUri = self.videoUri, let videoSettings = self.videoSettings else
            {
                self.error = NSError.activateResponseWithoutVideoUriError()
                
                return
            }
            
            do
            {
                let task = try sessionManager.videoSettingsTask(videoUri, videoSettings: videoSettings, destination: nil, completionHandler: nil)
                self.currentTaskIdentifier = task.taskIdentifier
                task.resume()
            }
            catch let error as NSError
            {
                self.error = error
            }
        }
    }
    
    // MARK: Private API
    
    private func cleanupAfterUpload()
    {
        self.removeObserverIfNecessary()
        
        if let path = self.url.path where NSFileManager.defaultManager().fileExistsAtPath(path)
        {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
        }
    }
    
    // MARK: KVO
    
    private func addObserver()
    {
        self.uploadProgressObject?.addObserver(self, forKeyPath: UploadDescriptor.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.progressKVOContext)
        self.isObserving = true
    }
    
    private func removeObserverIfNecessary()
    {
        if self.isObserving
        {
            self.uploadProgressObject?.removeObserver(self, forKeyPath: UploadDescriptor.ProgressKeyPath, context: &self.progressKVOContext)
            self.isObserving = false
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(UploadDescriptor.ProgressKeyPath, &self.progressKVOContext):
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                self.uploadProgress = progress
                print("Inner Upload: \(progress)")
                
            default:
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
        }
        else
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder)
    {
        self.url = aDecoder.decodeObjectForKey("url") as! NSURL // If force unwrap fails we have a big problem
        self.videoSettings = aDecoder.decodeObjectForKey("videoSettings") as? VideoSettings
        self.createVideoResponse = aDecoder.decodeObjectForKey("createVideoResponse") as? CreateVideoResponse
        self.videoUri = aDecoder.decodeObjectForKey("videoUri") as? String
        self.currentRequest = Request(rawValue: aDecoder.decodeObjectForKey("currentRequest") as! String)!

        super.init(coder: aDecoder)
    }
    
    override func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.url, forKey: "url")
        aCoder.encodeObject(self.videoSettings, forKey: "videoSettings")
        aCoder.encodeObject(self.createVideoResponse, forKey: "createVideoResponse")
        aCoder.encodeObject(self.videoUri, forKey: "videoUri")
        aCoder.encodeObject(self.currentRequest.rawValue, forKey: "currentRequest")
        
        super.encodeWithCoder(aCoder)
    }
}

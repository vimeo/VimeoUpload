//
//  VideoRefreshManager.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/14/15.
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

@objc protocol VideoRefreshManagerDelegate
{
    func videoDidFinishUploading(video: VIMVideo)
}

@objc class VideoRefreshManager: NSObject
{
    private static let RetryDelay: Double = 3
    
    // MARK:
    
    private let sessionManager: VimeoSessionManager
    private weak var delegate: VideoRefreshManagerDelegate?
    
    // MARK:
    
    private var videos: [VideoUri: VIMVideo] = [:]
    private let operationQueue: NSOperationQueue
    
    // MARK: - Initialization
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
        self.removeObservers()
    }
    
    init(sessionManager: VimeoSessionManager, delegate: VideoRefreshManagerDelegate)
    {
        self.sessionManager = sessionManager
        self.delegate = delegate
        
        self.operationQueue = NSOperationQueue()
        self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount // TODO: is this ok?
        
        super.init()
        
        self.addObservers()
        self.reachabilityDidChange(nil) // Set suspended state
    }
    
    // MARK: Public API
    
    func cancelAll()
    {
        self.videos.removeAll()
        self.operationQueue.cancelAllOperations()
    }
    
    func cancelRefreshForVideo(video: VIMVideo)
    {
        guard let uri = video.uri else
        {
            return
        }

        self.videos.removeValueForKey(uri)
    }
    
    func refreshVideo(video: VIMVideo)
    {
        guard let uri = video.uri where self.videos[uri] == nil else
        {
            return // It's already scheduled for refresh
        }

        self.doRefreshVideo(video)
    }
    
    // MARK: Private API
    
    private func doRefreshVideo(video: VIMVideo)
    {
        guard let uri = video.uri else
        {
            return
        }
        
        if self.dynamicType.isVideoStatusFinal(video) == true // No need to refresh this video, it's already done
        {
            return
        }
        
        self.videos[uri] = video
                
        let operation = VideoOperation(sessionManager: self.sessionManager, videoUri: uri)
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.cancelled == true
                {
                    return
                }
                
                guard let _ = strongSelf.videos[uri] else // The video refresh was cancelled
                {
                    return
                }
                
                if let error = operation.error
                {
                    if let response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse where response.statusCode == 404
                    {
                        strongSelf.videos.removeValueForKey(uri) // The video was deleted, remove it from consideration
                    }
                    else
                    {
                        strongSelf.retryVideo(video)
                    }
                }
                else if let freshVideo = operation.video
                {
                    if strongSelf.dynamicType.isVideoStatusFinal(freshVideo) == true // We're done!
                    {
                        strongSelf.videos.removeValueForKey(uri)
                        strongSelf.delegate?.videoDidFinishUploading(freshVideo)
                    }
                    else
                    {
                        strongSelf.retryVideo(video)
                    }
                }
                else // Execution should never reach this point
                {
                    strongSelf.videos.removeValueForKey(uri)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }

    private func retryVideo(video: VIMVideo)
    {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(self.dynamicType.RetryDelay * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] () -> Void in
            self?.doRefreshVideo(video)
        }
    }
    
    private static func isVideoStatusFinal(video: VIMVideo) -> Bool
    {
        let status = video.videoStatus
        
        return status == .Available || status == .UploadingError || status == .TranscodingError
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityDidChange:", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    func applicationWillEnterForeground(notification: NSNotification)
    {
        self.operationQueue.suspended = false 
    }
    
    func applicationDidEnterBackground(notification: NSNotification)
    {
        self.operationQueue.suspended = true
    }
    
    func reachabilityDidChange(notification: NSNotification?)
    {
        let currentlyReachable = AFNetworkReachabilityManager.sharedManager().reachable
        
        self.operationQueue.suspended = !currentlyReachable
    }
}
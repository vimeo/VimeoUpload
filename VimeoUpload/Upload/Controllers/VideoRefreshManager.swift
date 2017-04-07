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
import VimeoNetworking
import AFNetworking

@objc public protocol VideoRefreshManagerDelegate
{
    func uploadingStateDidChangeForVideo(_ video: VIMVideo)
}

@objc open class VideoRefreshManager: NSObject
{
    private static let RetryDelayInSeconds: Double = 3
    
    // MARK:
    
    private let sessionManager: VimeoSessionManager
    private weak var delegate: VideoRefreshManagerDelegate?
    
    // MARK:
    
    private var videos: [VideoUri: Bool] = [:]
    private let operationQueue: OperationQueue
    
    // MARK: - Initialization
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
        self.removeObservers()
    }
    
    public init(sessionManager: VimeoSessionManager, delegate: VideoRefreshManagerDelegate)
    {
        self.sessionManager = sessionManager
        self.delegate = delegate
        
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
        
        super.init()
        
        self.addObservers()
        self.reachabilityDidChange(nil) // Set suspended state
    }
    
    // MARK: Public API
    
    open func cancelAll()
    {
        self.videos.removeAll()
        self.operationQueue.cancelAllOperations()
    }
    
    open func cancelRefreshForVideoWithUri(_ uri: VideoUri)
    {
        self.videos.removeValue(forKey: uri)
    }

    open func refreshVideo(_ video: VIMVideo)
    {
        guard let uri = video.uri else
        {
            assertionFailure("Attempt to schedule refresh for a video with no uri")
            return 
        }

        guard self.videos[uri] == nil else
        {
            return // It's already scheduled for refresh
        }

        guard type(of: self).isVideoStatusFinal(video) != true else
        {
            return // No need to refresh this video, it's already done
        }

        self.doRefreshVideo(video)
    }
    
    // MARK: Private API

    private func doRefreshVideo(_ video: VIMVideo)
    {
        let uri = video.uri!
        
        self.videos[uri] = true
                
        let operation = VideoOperation(sessionManager: self.sessionManager, videoUri: uri)
        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
                {
                    return
                }
                
                guard let _ = strongSelf.videos[uri] else // The video refresh was cancelled
                {
                    return
                }
                
                if let error = operation.error
                {
                    if let response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? HTTPURLResponse, response.statusCode == 404
                    {
                        strongSelf.videos.removeValue(forKey: uri) // The video was deleted, remove it from consideration
                    }
                    else
                    {
                        strongSelf.retryVideo(video)
                    }
                }
                else if let freshVideo = operation.video
                {
                    if type(of: strongSelf).isVideoStatusFinal(freshVideo) == true // We're done!
                    {
                        strongSelf.videos.removeValue(forKey: uri)
                        strongSelf.delegate?.uploadingStateDidChangeForVideo(freshVideo)
                        
                        return
                    }
                    
                    let existingStatus = video.videoStatus
                    let newStatus = freshVideo.videoStatus

                    if existingStatus == newStatus
                    {
                        strongSelf.retryVideo(freshVideo) // Nothing has changed, just retry
                    }
                    else
                    {
                        strongSelf.delegate?.uploadingStateDidChangeForVideo(freshVideo)
                        strongSelf.retryVideo(freshVideo)
                    }
                }
                else // Execution should never reach this point
                {
                    strongSelf.videos.removeValue(forKey: uri)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }

    private func retryVideo(_ video: VIMVideo)
    {
        let delayTime = DispatchTime.now() + Double(Int64(type(of: self).RetryDelayInSeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] () -> Void in
            self?.doRefreshVideo(video)
        }
    }
    
    private static func isVideoStatusFinal(_ video: VIMVideo) -> Bool
    {
        let status = video.videoStatus
        
        return status == .available || status == .uploadingError || status == .transcodingError || status == .quotaExceeded
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoRefreshManager.reachabilityDidChange(_:)), name: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil)
    }
    
    func applicationWillEnterForeground(_ notification: NSNotification)
    {
        self.operationQueue.isSuspended = false 
    }
    
    func applicationDidEnterBackground(_ notification: NSNotification)
    {
        self.operationQueue.isSuspended = true
    }
    
    func reachabilityDidChange(_ notification: NSNotification?)
    {
        let currentlyReachable = AFNetworkReachabilityManager.shared().isReachable
        
        self.operationQueue.isSuspended = !currentlyReachable
    }
}

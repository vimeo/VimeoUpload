//
//  UploadDescriptor.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/21/15.
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

@objc open class UploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    private struct Constants {
        static let FileNameCoderKey = "fileName"
        static let FileExtensionCoderKey = "fileExtension"
        static let UploadTicketCoderKey = "uploadTicket"
        static let VideoCoderKey = "video"

        static let MaxAttempts = 10
    }

    // MARK: 
    
    @objc public var url: URL
    @objc public var video: VIMVideo?
    
    // MARK: VideoDescriptor
    
    @objc public var descriptorType: VideoDescriptorType
    {
        return .upload
    }
    
    @objc public var videoUri: VideoUri?
    {
        return self.video?.uri
    }
    
    @objc public var progressDescriptor: ProgressDescriptor
    {
        return self
    }
    
    open var uploadStrategy: UploadStrategy.Type = StreamingUploadStrategy.self
    
    // MARK: - Initialization
    
    @objc required public init()
    {
        fatalError("init() has not been implemented")
    }

    @objc public init(url: URL, video: VIMVideo)
    {
        self.url = url
        self.video = video
        
        super.init()
    }

    // MARK: Overrides
    
    @objc override open func prepare(sessionManager: AFURLSessionManager) throws
    {
        // TODO: Do we need to set self.state == .Ready here? [AH] 2/22/2016
        
        do
        {
            guard let video = self.video else
            {
                throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }
            
            let uploadLink = try self.uploadStrategy.uploadLink(from: video)
            let sessionManager = sessionManager as! VimeoSessionManager
            
            let uploadRequest = try self.uploadStrategy.uploadRequest(requestSerializer: sessionManager.requestSerializer as? VimeoRequestSerializer, fileUrl: self.url, uploadLink: uploadLink)
            let task = sessionManager.uploadVideoTask(source: self.url, request: uploadRequest, completionHandler: nil)
            
            self.currentTaskIdentifier = task.taskIdentifier
        }
        catch let error as NSError
        {
            self.currentTaskIdentifier = nil
            self.error = error
            self.state = .finished

            throw error // Propagate this out so that DescriptorManager can remove the descriptor from the set
        }
    }
    
    @objc override open func resume(sessionManager: AFURLSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
         if let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTask(for: identifier),
            let progress = sessionManager.uploadProgress(for: task)
        {
            self.progress = progress
        }
    }
    
    @objc override open func cancel(sessionManager: AFURLSessionManager)
    {
        super.cancel(sessionManager: sessionManager)
        
        FileManager.default.deleteFile(at: self.url)
    }

    @objc override open func didLoadFromCache(sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTask(for: identifier),
            let progress = sessionManager.uploadProgress(for: task) else
        {
            // This error is thrown if you initiate an upload and then kill the app from the multitasking view in mid-upload
            // Upon reopening the app, the descriptor is loaded but no longer has a task 
         
            FileManager.default.deleteFile(at: self.url)

            let error = NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
            self.error = error // TODO: Whenever we set error delete local file? Same for download?
            self.state = .finished
            
            throw error
        }

        self.progress = progress
    }
    
    @objc override open func taskDidComplete(sessionManager: AFURLSessionManager, task: URLSessionTask, error: NSError?)
    {
        self.currentTaskIdentifier = nil

        if self.isCancelled
        {
            assertionFailure("taskDidComplete was called for a cancelled descriptor.")

            return
        }

        if self.state == .suspended
        {
            assertionFailure("taskDidComplete was called for a suspended descriptor.")

            return
        }

        if self.error == nil
        {
            if let taskError = task.error // task.error is reserved for client-side errors, so check it first
            {
                self.error = (taskError as NSError).error(byAddingDomain: UploadErrorDomain.Upload.rawValue)
            }
            else if let error = error
            {
                self.error = error.error(byAddingDomain: UploadErrorDomain.Upload.rawValue)
            }
        }

        FileManager.default.deleteFile(at: self.url)

        self.state = .finished
    }
    
    // MARK: NSCoding
    
    @objc required public init(coder aDecoder: NSCoder)
    {        
        let fileName = aDecoder.decodeObject(forKey: type(of: self).Constants.FileNameCoderKey) as! String
        let fileExtension = aDecoder.decodeObject(forKey: type(of: self).Constants.FileExtensionCoderKey) as! String
        let path = URL.uploadDirectory().appendingPathComponent(fileName).appendingPathExtension(fileExtension).absoluteString
        
        self.url = URL(fileURLWithPath: path)

        // Support migrating archived uploadTickets to videos for API versions less than v3.4
        if let uploadTicket = aDecoder.decodeObject(forKey: type(of: self).Constants.UploadTicketCoderKey) as? VIMUploadTicket
        {
            self.video = uploadTicket.video
        }
        else
        {
            self.video = aDecoder.decodeObject(forKey: type(of: self).Constants.VideoCoderKey) as? VIMVideo
        }

        super.init(coder: aDecoder)
    }

    @objc override open func encode(with aCoder: NSCoder)
    {
        let fileName = self.url.deletingPathExtension().lastPathComponent
        let ext = self.url.pathExtension

        aCoder.encode(fileName, forKey: type(of: self).Constants.FileNameCoderKey)
        aCoder.encode(ext, forKey: type(of: self).Constants.FileExtensionCoderKey)
        aCoder.encode(self.video, forKey: type(of: self).Constants.VideoCoderKey)
        
        super.encode(with: aCoder)
    }
    
    // MARK: - Retriable
    
    @objc override public func shouldRetry(urlResponse: URLResponse?) -> Bool
    {
        return self.uploadStrategy.shouldRetry(urlResponse: urlResponse) && self.retryAttemptCount < Constants.MaxAttempts - 1
    }
}

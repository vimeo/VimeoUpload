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

class UploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    private static let FileNameCoderKey = "fileName"
    private static let FileExtensionCoderKey = "fileExtension"
    private static let UploadTicketCoderKey = "uploadTicket"

    // MARK: 
    
    var url: NSURL
    var uploadTicket: VIMUploadTicket
    
    // MARK: VideoDescriptor
    
    var type: VideoDescriptorType
    {
        return .Upload
    }
    
    var videoUri: VideoUri?
    {
        return self.uploadTicket.video?.uri
    }
    
    var progressDescriptor: ProgressDescriptor
    {
        return self
    }
    
    // MARK: - Initialization
    
    required init()
    {
        fatalError("init() has not been implemented")
    }

    init(url: NSURL, uploadTicket: VIMUploadTicket)
    {
        self.url = url
        self.uploadTicket = uploadTicket
        
        super.init()
    }

    // MARK: Overrides
    
    override func prepare(sessionManager sessionManager: AFURLSessionManager) throws
    {
        // TODO: Do we need to set self.state == .Ready here? [AH] 2/22/2016
        
        do
        {
            guard let uploadLinkSecure = self.uploadTicket.uploadLinkSecure else
            {
                // TODO: delete file here? Same in download?
                
                throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }
            
            let sessionManager = sessionManager as! VimeoSessionManager
            let task = try sessionManager.uploadVideoTask(source: self.url, destination: uploadLinkSecure, progress: &self.progress, completionHandler: nil)
            
            self.currentTaskIdentifier = task.taskIdentifier
        }
        catch let error as NSError
        {
            self.currentTaskIdentifier = nil
            self.error = error
            self.state = .Finished

            throw error // Propagate this out so that DescriptorManager can remove the descriptor from the set
        }
    }
    
    override func resume(sessionManager sessionManager: AFURLSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
         if let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTaskForIdentifier(identifier),
            let progress = sessionManager.uploadProgressForTask(task)
        {
            self.progress = progress
        }
    }
    
    override func cancel(sessionManager sessionManager: AFURLSessionManager)
    {
        super.cancel(sessionManager: sessionManager)
        
        NSFileManager.defaultManager().deleteFileAtURL(self.url)
    }

    override func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTaskForIdentifier(identifier),
            let progress = sessionManager.uploadProgressForTask(task) else
        {
            // This error is thrown if you initiate an upload and then kill the app from the multitasking view in mid-upload
            // Upon reopening the app, the descriptor is loaded but no longer has a task 
         
            NSFileManager.defaultManager().deleteFileAtURL(self.url)

            let error = NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
            self.error = error // TODO: Whenever we set error delete local file? Same for download?
            self.state = .Finished
            
            throw error
        }

        self.progress = progress
    }
    
    override func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        self.currentTaskIdentifier = nil

        if self.isCancelled
        {
            assertionFailure("taskDidComplete was called for a cancelled descriptor.")

            return
        }

        if self.state == .Suspended
        {
            assertionFailure("taskDidComplete was called for a suspended descriptor.")

            return
        }

        if self.error == nil
        {
            if let taskError = task.error // task.error is reserved for client-side errors, so check it first
            {
                self.error = taskError.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
            }
            else if let error = error
            {
                self.error = error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
            }
        }

        NSFileManager.defaultManager().deleteFileAtURL(self.url)

        self.state = .Finished
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder)
    {
        let fileName = aDecoder.decodeObjectForKey(self.dynamicType.FileNameCoderKey) as! String 
        let fileExtension = aDecoder.decodeObjectForKey(self.dynamicType.FileExtensionCoderKey) as! String
        let path = NSURL.uploadDirectory().URLByAppendingPathComponent(fileName).URLByAppendingPathExtension(fileExtension).absoluteString
        
        self.url = NSURL.fileURLWithPath(path)
        self.uploadTicket = aDecoder.decodeObjectForKey(self.dynamicType.UploadTicketCoderKey) as! VIMUploadTicket

        super.init(coder: aDecoder)
    }

    override func encodeWithCoder(aCoder: NSCoder)
    {
        let fileName = self.url.URLByDeletingPathExtension!.lastPathComponent
        let ext = self.url.pathExtension

        aCoder.encodeObject(fileName, forKey: self.dynamicType.FileNameCoderKey)
        aCoder.encodeObject(ext, forKey: self.dynamicType.FileExtensionCoderKey)
        aCoder.encodeObject(self.uploadTicket, forKey: self.dynamicType.UploadTicketCoderKey)
        
        super.encodeWithCoder(aCoder)
    }
}

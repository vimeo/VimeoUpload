//
//  SimpleUploadDescriptor.swift
//  VimeoUpload-iOS-2Step
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

class SimpleUploadDescriptor: Descriptor
{
    let url: NSURL
    let uploadTicket: VIMUploadTicket
    let assetIdentifier: String // Used to track the original ALAsset or PHAsset
    
    // MARK:
    
    private(set) var progress: NSProgress?
    
    // MARK:
    
    override var error: NSError?
    {
        didSet
        {
            if error != nil
            {
                self.currentTaskIdentifier = nil
                self.state = .Finished
            }
        }
    }
    
    // MARK:
    // MARK: Initialization
    
    init(url: NSURL, uploadTicket: VIMUploadTicket, assetIdentifier: String)
    {
        self.url = url
        self.uploadTicket = uploadTicket
        self.assetIdentifier = assetIdentifier
        
        super.init()
    }

    // MARK: Overrides
    
    override func prepare(sessionManager sessionManager: AFURLSessionManager) throws
    {
        do
        {
            guard let uploadLinkSecure = self.uploadTicket.uploadLinkSecure else
            {
                throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Attempt to initiate upload but the uploadUri is nil."])
            }
            
            let sessionManager = sessionManager as! VimeoSessionManager
            let task = try sessionManager.uploadVideoTask(source: self.url, destination: uploadLinkSecure, progress: &self.progress, completionHandler: nil)
            
            self.currentTaskIdentifier = task.taskIdentifier
        }
        catch let error as NSError
        {
            self.error = error
            
            throw error // Propagate this out so that DescriptorManager can remove the descriptor from the set
        }
    }
    
    override func resume(sessionManager sessionManager: AFURLSessionManager)
    {
        super.resume(sessionManager: sessionManager)
        
        if let identifier = self.currentTaskIdentifier,
            let task = sessionManager.taskForIdentifier(identifier) as? NSURLSessionUploadTask,
            let progress = sessionManager.uploadProgressForTask(task)
        {
            self.progress = progress
        }
    }
    
    override func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier,
            let task = sessionManager.taskForIdentifier(identifier) as? NSURLSessionUploadTask,
            let progress = sessionManager.uploadProgressForTask(task) else
        {
            // This error is thrown if you initiate an upload and then kill the app from the multitasking view in mid-upload
            // Upon reopening the app, the descriptor is loaded but no longer has a task 
            
            throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
        }

        self.progress = progress
    }
    
    override func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        NSFileManager.defaultManager().deleteFileAtURL(self.url)
        
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
        
        if self.error != nil
        {
            return
        }
        
        self.currentTaskIdentifier = nil
        self.state = .Finished
    }

    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder)
    {
        self.url = aDecoder.decodeObjectForKey("url") as! NSURL // If force unwrap fails we have a big problem
        self.uploadTicket = aDecoder.decodeObjectForKey("uploadTicket") as! VIMUploadTicket
        self.assetIdentifier = aDecoder.decodeObjectForKey("assetIdentifier") as! String

        super.init(coder: aDecoder)
    }
    
    override func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.url, forKey: "url")
        aCoder.encodeObject(self.uploadTicket, forKey: "uploadTicket")
        aCoder.encodeObject(self.assetIdentifier, forKey: "assetIdentifier")
        
        super.encodeWithCoder(aCoder)
    }
}

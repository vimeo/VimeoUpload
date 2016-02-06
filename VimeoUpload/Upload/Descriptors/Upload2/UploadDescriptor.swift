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

class UploadDescriptor: ProgressDescriptor, VideoDescriptor
{
    private static let FileNameCoderKey = "fileName"
    private static let FileExtensionCoderKey = "fileExtension"
    private static let UploadTicketCoderKey = "uploadTicket"
    private static let AssetIdentifierCoderKey = "assetIdentifier"

    // MARK: 
    
    let url: NSURL
    let uploadTicket: VIMUploadTicket
    let assetIdentifier: String // Used to track the original ALAsset or PHAsset
    
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
            let task = sessionManager.uploadTaskForIdentifier(identifier),
            let progress = sessionManager.uploadProgressForTask(task)
        {
            self.progress = progress
        }
    }
    
    override func didLoadFromCache(sessionManager sessionManager: AFURLSessionManager) throws
    {
        guard let identifier = self.currentTaskIdentifier,
            let task = sessionManager.uploadTaskForIdentifier(identifier),
            let progress = sessionManager.uploadProgressForTask(task) else
        {
            // TODO: can we handle this better? [AH]
            // This error is thrown if you initiate an upload and then kill the app from the multitasking view in mid-upload
            // Upon reopening the app, the descriptor is loaded but no longer has a task 
            
            throw NSError(domain: UploadErrorDomain.Upload.rawValue, code: 0, userInfo: [NSLocalizedDescriptionKey: "Loaded descriptor from cache that does not have a task associated with it."])
        }

        self.progress = progress
    }
    
    override func taskDidComplete(sessionManager sessionManager: AFURLSessionManager, task: NSURLSessionTask, error: NSError?)
    {
        if let error = error where self.state == .Suspended && error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
        {
            let _ = try? self.prepare(sessionManager: sessionManager) // An error can be set within prepare
            
            return
        }
                
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
        self.assetIdentifier = aDecoder.decodeObjectForKey(self.dynamicType.AssetIdentifierCoderKey) as! String

        super.init(coder: aDecoder)
    }
    
    override func encodeWithCoder(aCoder: NSCoder)
    {
        let fileName = self.url.URLByDeletingPathExtension!.lastPathComponent
        let ext = self.url.pathExtension

        aCoder.encodeObject(fileName, forKey: self.dynamicType.FileNameCoderKey)
        aCoder.encodeObject(ext, forKey: self.dynamicType.FileExtensionCoderKey)
        aCoder.encodeObject(self.uploadTicket, forKey: self.dynamicType.UploadTicketCoderKey)
        aCoder.encodeObject(self.assetIdentifier, forKey: self.dynamicType.AssetIdentifierCoderKey)
        
        super.encodeWithCoder(aCoder)
    }
}

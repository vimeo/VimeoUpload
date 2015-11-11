//
//  MyVimeoSessionManager.swift
//  VimeoUpload-iOS-Example
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

import UIKit

class UploadManager
{
    static let sharedInstance = UploadManager()
    
    let descriptorManager: DescriptorManager
    private let reporter: DescriptorManagerDelegate
    
    init()
    {
        self.reporter = UploadReporter()
        
        let sessionManager = VimeoSessionManager(authToken: "caf4648129ec56e580175c4b45cce7fc--")
        self.descriptorManager = DescriptorManager(sessionManager: sessionManager, delegate: self.reporter)
    }
    
    // TODO: respond to logout event
    
    
    
    // TODO: move this into test cases
    
//    func upload(descriptor: UploadDescriptor) throws
//    {
//        try self.create(descriptor)
//    }
//        
//    private func create(descriptor: UploadDescriptor) throws
//    {
//        // TODO: handle these errors better so we don't need to force unwrap task below?
//        
//        let task = try self.createVideoDownloadTask(url: descriptor.url, destination: nil, completionHandler: { [weak self] (response, error) -> Void in
//
//            guard let strongSelf = self else
//            {
//                return
//            }
//
//            if let error = error
//            {
//                print(error)
//
//                return
//            }
//
//            descriptor.createVideoResponse = response
//
//            do
//            {
//                try strongSelf.uploadFile(descriptor)
//            }
//            catch let error as NSError
//            {
//                print(error)
//            }
//        })
//        
//        task.resume()
//    }
//    
//    private func uploadFile(descriptor: UploadDescriptor) throws
//    {
//        let task = try self.uploadVideoTask(descriptor.url, destination: descriptor.createVideoResponse!.uploadUri, progress: nil, completionHandler: { [weak self] (error) -> Void in
//
//            guard let strongSelf = self else
//            {
//                return
//            }
//
//            if let error = error
//            {
//                print(error)
//
//                return
//            }
//
//            do
//            {
//                try strongSelf.activateVideo(descriptor)
//            }
//            catch let error as NSError
//            {
//                print(error)
//            }
//        })
//        
//        task.resume()
//    }
//    
//    private func activateVideo(descriptor: UploadDescriptor) throws
//    {
//        let task = try self.activateVideoTask(descriptor.createVideoResponse!.activationUri, destination: nil, completionHandler: { [weak self] (value, error) -> Void in
//
//            guard let strongSelf = self else
//            {
//                return
//            }
//            
//            if let error = error
//            {
//                print(error)
//                // TODO: do something related to state
//                
//                return
//            }
//
//            descriptor.videoUri = value
//            
//        })
//        
//        task.resume()
//    }
}

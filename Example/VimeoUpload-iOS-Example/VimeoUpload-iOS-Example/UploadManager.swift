//
//  MyVimeoSessionManager.swift
//  VimeoUpload-iOS-Example
//
//  Created by Alfred Hanssen on 10/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
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
        
        let sessionManager = VimeoSessionManager(authToken: "caf4648129ec56e580175c4b45cce7fc")
        self.descriptorManager = DescriptorManager(sessionManager: sessionManager, delegate: self.reporter)
    }
        
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

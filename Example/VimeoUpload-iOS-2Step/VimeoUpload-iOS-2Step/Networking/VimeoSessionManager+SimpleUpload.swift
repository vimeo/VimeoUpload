//
//  VimeoSessionManager+SimpleUpload.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/21/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension VimeoSessionManager
{
    func createVideoDataTask(url url: NSURL, videoSettings: VideoSettings?, completionHandler: UploadTicketCompletionHandler) throws -> NSURLSessionDataTask
    {
        let request = try (self.requestSerializer as! VimeoRequestSerializer).createVideoRequestWithUrl(url, videoSettings: videoSettings)
        
        let task = self.dataTaskWithRequest(request, completionHandler: { [weak self] (response, responseObject, error) -> Void in
            
            // Do model parsing on a background thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                do
                {
                    let uploadTicket = try (strongSelf.responseSerializer as! VimeoResponseSerializer).processCreateVideoResponse(response, responseObject: responseObject, error: error)
                    completionHandler(uploadTicket: uploadTicket, error: nil)
                }
                catch let error as NSError
                {
                    completionHandler(uploadTicket: nil, error: error)
                }
            })
        })
        
        task.taskDescription = TaskDescription.CreateVideo.rawValue
        
        return task
    }
}
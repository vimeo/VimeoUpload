//
//  CAMUploadReqest.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/27/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public enum CAMUploadRequest: String
{
    case CreateVideo
    case UploadVideo
    case CreateThumbnail
    case UploadThumbnail
    case ActivateThumbnail
    
    static func orderedRequests() -> [CAMUploadRequest]
    {
        return [.CreateVideo, .UploadVideo, .CreateThumbnail, .UploadThumbnail, .ActivateThumbnail]
    }
    
    static func nextRequest(currentRequest: CAMUploadRequest) -> CAMUploadRequest?
    {
        let orderedRequests = CAMUploadRequest.orderedRequests()
        if let index = orderedRequests.indexOf(currentRequest) where index + 1 < orderedRequests.count
        {
            return orderedRequests[index + 1]
        }
        
        return nil
    }
}

//
//  VimeoRequestSerializer+SimpleUpload.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/20/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension VimeoRequestSerializer
{
    func createVideoRequestWithUrl(url: NSURL, videoSettings: VideoSettings?) throws -> NSMutableURLRequest
    {
        var parameters = try self.createVideoRequestBaseParameters(url)
        parameters["create_clip"] = "true"
        
        if let videoSettings = videoSettings
        {
            for (key, value) in videoSettings.parameterDictionary()
            {
                parameters[key] = value
            }
        }

        let url = NSURL(string: "/me/videos", relativeToURL: VimeoBaseURLString)!
        
        return try self.createVideoRequestWithUrl(url, parameters: parameters)
    }
}
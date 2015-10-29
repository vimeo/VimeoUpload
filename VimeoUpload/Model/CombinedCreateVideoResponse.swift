//
//  CombinedCreateVideoResponse.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/21/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

class CombinedCreateVideoResponse: NSObject
{
    var uploadUri: String
    var videoUri: String

    init(uploadUri: String, videoUri: String)
    {
        self.uploadUri = uploadUri
        self.videoUri = videoUri
    }
}

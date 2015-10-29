//
//  CreateVideoResponse.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/12/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

class CreateVideoResponse: NSObject
{
    var uploadUri: String
    var activationUri: String
    
    init(uploadUri: String, activationUri: String)
    {
        self.uploadUri = uploadUri
        self.activationUri = activationUri
    }    

    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder)
    {
        self.uploadUri = aDecoder.decodeObjectForKey("uploadUri") as! String
        self.activationUri = aDecoder.decodeObjectForKey("activationUri") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.uploadUri, forKey: "uploadUri")
        aCoder.encodeObject(self.activationUri, forKey: "activationUri")
    }
}


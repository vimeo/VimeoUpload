//
//  VideoSettings.swift
//  VIMUpload
//
//  Created by Alfred Hanssen on 10/3/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

class VideoSettings: NSObject
{
    var title: String?
    var desc: String?
    var privacy: String
    var users: [String]? // List of uris of users who can view this video

    init(title: String?, description: String?, privacy: String, users: [String]?)
    {
        self.title = title
        self.desc = description
        self.privacy = privacy
        self.users = users
    }
    
    // MARK: NSCoding
    
    required init(coder aDecoder: NSCoder)
    {
        self.title = aDecoder.decodeObjectForKey("title") as? String
        self.desc = aDecoder.decodeObjectForKey("desc") as? String
        self.privacy = aDecoder.decodeObjectForKey("privacy") as! String
        self.users = aDecoder.decodeObjectForKey("users") as? [String]
    }
    
    func encodeWithCoder(aCoder: NSCoder)
    {
        aCoder.encodeObject(self.title, forKey: "title")
        aCoder.encodeObject(self.desc, forKey: "desc")
        aCoder.encodeObject(self.privacy, forKey: "privacy")
        aCoder.encodeObject(self.users, forKey: "users")
    }
}

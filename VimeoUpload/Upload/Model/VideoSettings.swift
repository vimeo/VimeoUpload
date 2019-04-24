//
//  VideoSettings.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 10/3/15.
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

@objc open class VideoSettings: NSObject, NSCoding
{
    @objc public var title: String?
    {
        didSet
        {
            self.title = self.trim(text: self.title)
        }
    }
    
    @objc public var desc: String?
    {
        didSet
        {
            self.desc = self.trim(text: self.desc)
        }
    }
    
    @objc public var privacy: String?
    @objc public var users: [String]? // List of uris of users who can view this video
    @objc public var password: String?

    @objc public init(title: String?, description: String?, privacy: String?, users: [String]?, password: String?)
    {
        super.init()
        
        self.privacy = privacy
        self.users = users
        self.password = password
        self.title = self.trim(text: title)
        self.desc = self.trim(text: description)
    }
    
    // MARK: Public API
    
    @objc open func parameterDictionary() -> [String: Any]
    {
        var parameters: [String: Any] = [:]
        
        if let title = self.title, title.count > 0
        {
            parameters["name"] = title
        }
        
        if let description = self.desc, description.count > 0
        {
            parameters["description"] = description
        }
        
        if let privacy = self.privacy, privacy.count > 0
        {
            parameters["privacy"] = (["view": privacy])
        }
        
        if let users = self.users
        {
            parameters["users"] = (users.map { ["uri": $0] })
        }
        
        if let password = self.password
        {
            parameters["password"] = password
        }

        return parameters
    }
    
    // MARK: NSCoding
    
    @objc required public init(coder aDecoder: NSCoder)
    {
        self.title = aDecoder.decodeObject(forKey: "title") as? String
        self.desc = aDecoder.decodeObject(forKey: "desc") as? String
        self.privacy = aDecoder.decodeObject(forKey: "privacy") as? String
        self.users = aDecoder.decodeObject(forKey: "users") as? [String]
        self.password = aDecoder.decodeObject(forKey: "password") as? String
    }
    
    @objc public func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.desc, forKey: "desc")
        aCoder.encode(self.privacy, forKey: "privacy")
        aCoder.encode(self.users, forKey: "users")
        aCoder.encode(self.password, forKey: "password")
    }
    
    // MARK : String Methods
    
    func trim(text: String?) -> String?
    {
        return text?.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

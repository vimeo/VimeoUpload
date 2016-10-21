//
//  KeyedArchiver.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/23/15.
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

class KeyedArchiver: ArchiverProtocol
{
    private static let ArchiveExtension = "archive"
    
    private let basePath: String

    init(basePath: String)
    {
        assert(NSFileManager.defaultManager().fileExistsAtPath(basePath, isDirectory: nil), "Invalid basePath")
        
        self.basePath = basePath
    }
    
    func loadObjectForKey(key: String) -> AnyObject?
    {
        let path = self.archivePath(key: key)
        
        return NSKeyedUnarchiver.unarchiveObjectWithFile(path)
    }
    
    func saveObject(object: AnyObject, key: String)
    {
        let path = self.archivePath(key: key)
        
        NSKeyedArchiver.archiveRootObject(object, toFile: path)
    }
    
    // MARK: Utilities
    
    func archivePath(key key: String) -> String
    {
        var URL = NSURL(string: self.basePath)!
        
        URL = URL.URLByAppendingPathComponent(key)!
        URL = URL.URLByAppendingPathExtension(self.dynamicType.ArchiveExtension)!
        
        return URL.absoluteString! as String
    }
}

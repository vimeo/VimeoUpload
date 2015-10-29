//
//  Archiver.swift
//  Pegasus
//
//  Created by Hanssen, Alfie on 10/23/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

class KeyedArchiver: ArchiverProtocol
{
    static let ArchiveExtension = "archive"
    
    func loadObjectForKey(key: String) -> AnyObject?
    {
        let path = self.archivePath(key)
        
        return NSKeyedUnarchiver.unarchiveObjectWithFile(path)
    }
    
    func saveObject(object: AnyObject, key: String)
    {
        let path = self.archivePath(key)
        
        NSKeyedArchiver.archiveRootObject(object, toFile: path)
    }
    
    // MARK: Utilities
    
    func archivePath(key: String) -> String
    {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        var URL = NSURL(string: path)!
        
        URL = URL.URLByAppendingPathComponent(key)
        URL = URL.URLByAppendingPathExtension(KeyedArchiver.ArchiveExtension)
        
        return URL.absoluteString as String
    }
}
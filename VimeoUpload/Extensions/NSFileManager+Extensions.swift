//
//  NSFileManager+Extensions.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension NSFileManager
{
    func freeDiskSpace() throws -> NSNumber?
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let dictionary = try self.attributesOfFileSystemForPath(documentsPath)

        return dictionary[NSFileSystemSize] as? NSNumber
    }
    
    func canUploadFile(url: NSURL) -> Bool
    {
        // TODO: check that this is a video file
        
        guard let path = url.path else
        {
            return false
        }
        
        var isDirectory: ObjCBool = false
        let fileExists = self.fileExistsAtPath(path, isDirectory: &isDirectory)
        let isReadable = self.isReadableFileAtPath(path)
        
        return fileExists && Bool(isDirectory) == false && isReadable
    }
}
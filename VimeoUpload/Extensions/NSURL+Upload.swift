//
//  NSURL+Extensions.swift
//  Pegasus
//
//  Created by Hanssen, Alfie on 10/16/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

#if os(iOS)
    import MobileCoreServices
#elseif os(OSX)
    import CoreServices
#endif

extension NSURL
{
    func vimeoUploadExportURL(fileType: String) throws -> NSURL
    {
        var url = self.URLByAppendingPathComponent("vimeo_uploads")

        let unmanagedTag = UTTypeCopyPreferredTagWithClass(fileType, kUTTagClassFilenameExtension)!
        let ext = unmanagedTag.takeRetainedValue() as String

        url = try self.prepareURL(ext)
        
        return NSURL.fileURLWithPath(url.absoluteString)
    }

    func vimeoDownloadDataURL() throws -> NSURL
    {
        var url = self.URLByAppendingPathComponent("vimeo_download_data")
        
        url = try self.prepareURL("data")
        
        return NSURL.fileURLWithPath(url.absoluteString)
    }
    
    private func prepareURL(ext: String) throws -> NSURL
    {
        if NSFileManager.defaultManager().fileExistsAtPath(self.absoluteString) == false
        {
            try NSFileManager.defaultManager().createDirectoryAtPath(self.absoluteString, withIntermediateDirectories: true, attributes: nil)
        }
        
        let filename = NSProcessInfo.processInfo().globallyUniqueString
        var url = self.URLByAppendingPathComponent(filename)
        
        url = url.URLByAppendingPathExtension(ext)

        return url
    }
}
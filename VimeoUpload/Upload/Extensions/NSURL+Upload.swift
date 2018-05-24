//
//  NSURL+Upload.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/16/15.
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

#if os(iOS)
    import MobileCoreServices
#elseif os(OSX)
    import CoreServices
#endif

public extension URL
{
    static func uploadURL(documentsFolderURL: URL? = nil, withFileName filename: String, fileType: String) throws -> URL
    {
        let url = URL.uploadDirectory(documentsFolderURL: documentsFolderURL)
        
        if FileManager.default.fileExists(atPath: url.path) == false
        {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        let unmanagedTag = UTTypeCopyPreferredTagWithClass(fileType as CFString, kUTTagClassFilenameExtension)!
        let ext = unmanagedTag.takeRetainedValue() as String
        let path = url.appendingPathComponent(filename).appendingPathExtension(ext)
        
        return path
    }
    
    static func uploadDirectory(documentsFolderURL: URL? = nil) -> URL
    {
        let documentsURL: URL
        
        if let documentsFolderURL = documentsFolderURL
        {
            documentsURL = documentsFolderURL
        }
        else
        {
            do
            {
                documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            }
            catch
            {
                fatalError("Failure: Documents folder does not exist.")
            }
        }
        
        return documentsURL.appendingPathComponent("uploader").appendingPathComponent("videos")
    }
}

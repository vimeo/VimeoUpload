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

public class KeyedArchiver: ArchiverProtocol
{
    private struct Constants
    {
        static let ArchiveExtension = "archive"
        static let UnderscoreText = "_"
    }
    
    private let basePath: String
    private let prefix: String?

    public init(basePath: String, archivePrefix: String? = nil)
    {
        assert(FileManager.default.fileExists(atPath: basePath, isDirectory: nil), "Invalid basePath")
        
        self.basePath = basePath
        self.prefix = archivePrefix
    }
    
    public func loadObject(for key: String) -> Any?
    {
        let path = self.archivePath(key: self.key(withPrefix: self.prefix, key: key))
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: path)
    }
    
    public func save(object: Any, key: String)
    {
        let path = self.archivePath(key: self.key(withPrefix: self.prefix, key: key))
        
        NSKeyedArchiver.archiveRootObject(object, toFile: path)
    }
    
    // MARK: Utilities
    
    func archivePath(key: String) -> String
    {
        var url = URL(string: self.basePath)!
        
        url = url.appendingPathComponent(key)
        url = url.appendingPathExtension(Constants.ArchiveExtension)
        
        return url.absoluteString as String
    }
    
    private func key(withPrefix prefix: String?, key: String) -> String
    {
        guard let prefix = prefix else
        {
            return key
        }
        
        return prefix + Constants.UnderscoreText + key
    }
}

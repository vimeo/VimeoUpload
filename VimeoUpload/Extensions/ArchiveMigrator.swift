//
//  ArchiveMigrating.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 6/1/18.
//  Copyright © 2018 Vimeo. All rights reserved.
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

class ArchiveMigrator: ArchiveMigrating
{
    private let fileManager: FileManager
    private let documentsFolderURL: URL
    
    init?(fileManager: FileManager)
    {
        guard let documentsFolderURL = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else
        {
            return nil
        }
        
        self.documentsFolderURL = documentsFolderURL
        self.fileManager = fileManager
    }
    
    func archiveFileExists(relativeFilePath: String) -> Bool
    {
        let fileURL = self.fileURL(withRelativeFilePath: relativeFilePath)
        
        return self.fileManager.fileExists(atPath: fileURL.path)
    }
    
    func loadArchiveFile(relativeFilePath: String) -> Any?
    {
        let fileURL = self.fileURL(withRelativeFilePath: relativeFilePath)
        
        return NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.path)
    }
    
    func deleteArchiveFile(relativeFilePath: String)
    {
        guard self.archiveFileExists(relativeFilePath: relativeFilePath) == true else
        {
            return
        }
        
        let fileURL = self.fileURL(withRelativeFilePath: relativeFilePath)
        
        try? self.fileManager.removeItem(at: fileURL)
    }
    
    private func fileURL(withRelativeFilePath relativeFilePath: String) -> URL
    {
        return self.documentsFolderURL.appendingPathComponent(relativeFilePath)
    }
}

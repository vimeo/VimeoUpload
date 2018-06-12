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

public protocol ArchiveMigrating
{
    func archiveFileExists(relativeFilePath: String) -> Bool
    
    func loadArchiveFile(relativeFilePath: String) -> Any?
    
    func deleteArchiveFile(relativeFilePath: String)
}

struct ArchiveDataLoader
{
    static func loadData(relativeFolderPath: String, archiver: KeyedArchiver, key: String, migrator: ArchiveMigrating?) -> Any?
    {
        let dataAtNewLocation = archiver.loadObject(for: key)
        
        guard let migrator = migrator else
        {
            return dataAtNewLocation
        }
        
        let relativeFilePath = relativeFolderPath + "/" + key + ".archive"
        
        guard migrator.archiveFileExists(relativeFilePath: relativeFilePath) == true else
        {
            return dataAtNewLocation
        }
        
        guard let dataAtOldLocation = migrator.loadArchiveFile(relativeFilePath: relativeFilePath) else
        {
            return dataAtNewLocation
        }
        
        migrator.deleteArchiveFile(relativeFilePath: relativeFilePath)
        
        return dataAtOldLocation
    }
}

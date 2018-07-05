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

/// Classes conforming to the `ArchiveMigrating` protocol can move
/// upload data from one sandbox to another. This protocol is for
/// internal use only.
protocol ArchiveMigrating
{
    /// Provides a means for the client to determine if an archive exists
    /// at a file path relative to a Documents folder.
    ///
    /// - Parameter relativeFileURL: The relative URL of the archive file.
    /// - Returns: `true` if the archive file exists.
    func archiveFileExists(relativeFileURL: URL) -> Bool
    
    /// Provides a means for the client to load an archive file into
    /// memory.
    ///
    /// - Parameter relativeFilePath: The relative path of the archive file.
    /// - Returns: The data from the archive file.
    func loadArchiveFile(relativeFileURL: URL) -> Any?
    
    /// Provides a means for the client to delete an archive file.
    ///
    /// - Parameter relativeFilePath: The relative path of the archive file.
    func deleteArchiveFile(relativeFileURL: URL)
}

struct ArchiveDataLoader
{
    static func loadData(relativeFolderURL: URL?, archiver: KeyedArchiver, key: String, migrator: ArchiveMigrating?) -> Any?
    {
        let dataAtNewLocation = archiver.loadObject(for: key)

        guard let migrator = migrator,
            let relativeFileURL = URL(string: key + ".archive", relativeTo: relativeFolderURL),
            let dataAtOldLocation = migrator.loadArchiveFile(relativeFileURL: relativeFileURL)
        else
        {
            return dataAtNewLocation
        }
        
        migrator.deleteArchiveFile(relativeFileURL: relativeFileURL)
        
        return dataAtOldLocation
    }
}

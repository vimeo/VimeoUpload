//
//  ArchiveMigrating.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 6/1/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

public protocol ArchiveMigrating
{
    func archiveFileExists(relativeFilePath: String) -> Bool
    
    func loadArchiveFile(relativeFilePath: String) -> Any?
    
    func deleteArchiveFile(relativeFilePath: String)
}

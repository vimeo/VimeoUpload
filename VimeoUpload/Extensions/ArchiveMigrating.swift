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

struct ArchiveDataLoader
{
    static func loadData(withUploaderName uploaderName: String, archiver: KeyedArchiver, key: String, migrator: ArchiveMigrating?) -> Any?
    {
        let dataAtNewLocation = archiver.loadObject(for: key)
        
        guard let migrator = migrator else
        {
            return dataAtNewLocation
        }
        
        let relativeFilePath = uploaderName + "/" + key + ".archive"
        
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

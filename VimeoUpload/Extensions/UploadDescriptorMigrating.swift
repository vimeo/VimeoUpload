//
//  UploadDescriptorMigrating.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 6/1/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

protocol UploadDescriptorMigrating
{
    init(appSandboxDocumentsFolderURL: URL)
    
    var archiveFileExists: Bool { get }
    
    func loadArchiveFile() -> Set<Descriptor>
    
    func deleteArchiveFile()
}

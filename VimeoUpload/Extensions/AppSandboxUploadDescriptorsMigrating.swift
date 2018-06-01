//
//  AppSandboxUploadDescriptorsMigrating.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 6/1/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

public protocol AppSandboxUploadDescriptorsMigrating
{
    var archiveFileExists: Bool { get }
    
    func loadArchiveFile() -> Set<Descriptor>
    
    func deleteArchiveFile()
}

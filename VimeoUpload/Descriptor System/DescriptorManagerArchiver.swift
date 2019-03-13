//
//  DescriptorManagerTracker.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/9/15.
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

// This class handles persistence of the descriptor list and the suspended state boolean to disk

class DescriptorManagerArchiver
{
    private static let DescriptorsArchiveKey = "descriptors"
    private static let SuspendedArchiveKey = "is_suspended"

    // MARK: 
    
    private let archiver: KeyedArchiver
    private(set) var descriptors = Set<Descriptor>()
    var suspended = false
    {
        didSet
        {
            self.saveSuspendedState()
        }
    }

    // MARK: - Initialization
    
    init?(name: String,
          archivePrefix: String?,
          documentsFolderURL: URL)
    {
        guard let archiver = type(of: self).setupArchiver(name: name, archivePrefix: archivePrefix, documentsFolderURL: documentsFolderURL) else
        {
            return nil
        }
        
        self.archiver = archiver
        
        let migrator = ArchiveMigrator(fileManager: FileManager.default)
        
        let relativeFolderURL = URL(string: name)
        self.descriptors = self.loadDescriptors(withMigrator: migrator, relativeFolderURL: relativeFolderURL)
        self.suspended = self.loadSuspendedState(withMigrator: migrator, relativeFolderURL: relativeFolderURL)
    }
    
    // MARK: Setup - Archiving
    
    private static func setupArchiver(name: String, archivePrefix: String?, documentsFolderURL: URL) -> KeyedArchiver?
    {
        let typeFolderURL = documentsFolderURL.appendingPathComponent(name)

        if FileManager.default.fileExists(atPath: typeFolderURL.path) == false
        {
            do
            {
                try FileManager.default.createDirectory(at: typeFolderURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                return nil
            }
        }
        
        return KeyedArchiver(basePath: typeFolderURL.path, archivePrefix: archivePrefix)
    }
    
    private func loadDescriptors(withMigrator migrator: ArchiveMigrating?, relativeFolderURL: URL?) -> Set<Descriptor>
    {
        guard let descriptors = ArchiveDataLoader.loadData(relativeFolderURL: relativeFolderURL,
                                                        archiver: self.archiver,
                                                        key: DescriptorManagerArchiver.DescriptorsArchiveKey) as? Set<Descriptor>
        else
        {
            return Set<Descriptor>()
        }
        
        return descriptors
    }
    
    private func saveDescriptors()
    {
        self.archiver.save(object: self.descriptors, key: type(of: self).DescriptorsArchiveKey)
    }
    
    private func loadSuspendedState(withMigrator migrator: ArchiveMigrating?, relativeFolderURL: URL?) -> Bool
    {
        guard let suspendedState = ArchiveDataLoader.loadData(relativeFolderURL: relativeFolderURL,
                                                              archiver: self.archiver,
                                                              key: DescriptorManagerArchiver.SuspendedArchiveKey) as? Bool
        else
        {
            return false
        }
        
        return suspendedState
    }
    
    private func saveSuspendedState()
    {
        self.archiver.save(object: self.suspended, key: type(of: self).SuspendedArchiveKey)
    }
    
    // MARK: Public API
    
    func save()
    {
        self.saveDescriptors()
    }
    
    func removeAll()
    {
        self.descriptors.removeAll()
        self.saveDescriptors()
    }
    
    func insert(descriptor: Descriptor)
    {
        self.descriptors.insert(descriptor)
        self.saveDescriptors()
    }
    
    func remove(descriptor: Descriptor)
    {
        self.descriptors.remove(descriptor)
        self.saveDescriptors()
    }
    
    func descriptor(passing test: TestClosure) -> Descriptor?
    {
        for currentDescriptor in self.descriptors
        {
            if test(currentDescriptor) == true
            {
                return currentDescriptor
            }
        }
        
        return nil
    }
}

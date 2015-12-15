//
//  DescriptorManagerTracker.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/9/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

class DescriptorManagerTracker
{
    private static let DescriptorsArchiveKey = "descriptors"
    private static let SuspendedArchiveKey = "suspended"

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

    // MARK: 
    // MARK: Initialization
    
    init(name: String)
    {
        self.archiver = self.dynamicType.setupArchiver(name: name)
        
        self.descriptors = self.loadDescriptors()
        self.suspended = self.loadSuspendedState()
    }
    
    // MARK: Setup - Archiving
    
    private static func setupArchiver(name name: String) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        var documentsURL = NSURL(string: documentsPath)!
        
        documentsURL = documentsURL.URLByAppendingPathComponent(name)
        documentsURL = documentsURL.URLByAppendingPathComponent(DescriptorManagerTracker.DescriptorsArchiveKey)
        
        if NSFileManager.defaultManager().fileExistsAtPath(documentsURL.path!) == false
        {
            try! NSFileManager.defaultManager().createDirectoryAtPath(documentsURL.path!, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path!)
    }
    
    private func loadDescriptors() -> Set<Descriptor>
    {
        return self.archiver.loadObjectForKey(self.dynamicType.DescriptorsArchiveKey) as? Set<Descriptor> ?? Set<Descriptor>()
    }
    
    private func saveDescriptors()
    {
        self.archiver.saveObject(self.descriptors, key: self.dynamicType.DescriptorsArchiveKey)
    }
    
    private func loadSuspendedState() -> Bool
    {
        return self.archiver.loadObjectForKey(self.dynamicType.SuspendedArchiveKey) as? Bool ?? false
    }
    
    private func saveSuspendedState()
    {
        self.archiver.saveObject(self.suspended, key: self.dynamicType.SuspendedArchiveKey)
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
    
    func descriptorPassingTest(test: TestBlock) -> Descriptor?
    {
        for currentDescriptor in self.descriptors
        {
            if test(descriptor: currentDescriptor) == true
            {
                return currentDescriptor
            }
        }
        
        return nil
    }
}
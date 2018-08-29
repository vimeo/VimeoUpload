//
//  UploadFailureTracker.swift
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

@objc public class VideoDescriptorFailureTracker: NSObject
{
    private static let ArchiveKey = "descriptors_failed"

    // MARK: 
    
    private let archiver: KeyedArchiver
    private var failedDescriptors: [String: Descriptor] = [:]

    // MARK: - Initialization
    
    deinit
    {
        self.removeObservers()
    }
    
    /// Initializes a descriptor failure tracker object. Upon creation, the
    /// object will attempt to create a folder to save the description of
    /// failed uploads if needed. If the folder already exists, it will
    /// attempt to load that information into memory if desired.
    ///
    /// The folder is created with the following scheme:
    ///
    /// ```
    /// Documents/name
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the folder that we'll store the archive.
    ///   - archivePrefix: The prefix of the archive file. You pass in the
    ///   prefix if you want to keep track of multiple archive files. By
    ///   default, it has the value of `nil`.
    ///   - documentsFolderURL: The Documents folder's URL in which the folder
    ///   is located.
    /// - Returns: `nil` if the keyed archiver cannot load descriptors' archive.
    public init?(name: String,
                 archivePrefix: String? = nil,
                 documentsFolderURL: URL)
    {
        guard let archiver = type(of: self).setupArchiver(folderName: name, archivePrefix: archivePrefix, documentsFolderURL: documentsFolderURL) else
        {
            return nil
        }
        
        self.archiver = archiver
        
        super.init()
        
        let migrator = ArchiveMigrator(fileManager: FileManager.default)
        
        let relativeFolderURL = URL(string: name)
        self.failedDescriptors = self.load(relativeFolderURL: relativeFolderURL, migrator: migrator)

        self.addObservers()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(folderName: String, archivePrefix: String?, documentsFolderURL: URL) -> KeyedArchiver?
    {
        let folderURL = documentsFolderURL.appendingPathComponent(folderName)
        
        if FileManager.default.fileExists(atPath: folderURL.path) == false
        {
            do
            {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                return nil
            }
        }
        
        return KeyedArchiver(basePath: folderURL.path, archivePrefix: archivePrefix)
    }
    
    private func load(relativeFolderURL: URL?, migrator: ArchiveMigrating?) -> [String: Descriptor]
    {
        guard let failedDescriptors = ArchiveDataLoader.loadData(relativeFolderURL: relativeFolderURL,
                                                                 archiver: self.archiver,
                                                                 key: VideoDescriptorFailureTracker.ArchiveKey) as? [String: Descriptor]
        else
        {
            return [:]
        }
        
        return failedDescriptors
    }
    
    private func save()
    {
        self.archiver.save(object: self.failedDescriptors, key: type(of: self).ArchiveKey)
    }
    
    // MARK: Public API
    
    public func removeAllFailures()
    {
        self.failedDescriptors.removeAll()
        self.save()
    }
    
    public func removeFailedDescriptor(for key: String) -> Descriptor?
    {
        guard let descriptor = self.failedDescriptors.removeValue(forKey: key) else
        {
            return nil
        }
        
        self.save()

        return descriptor
    }
    
    public func failedDescriptor(for key: String) -> Descriptor?
    {
        return self.failedDescriptors[key]
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoDescriptorFailureTracker.descriptorDidFail(_:)), name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoDescriptorFailureTracker.descriptorDidCancel(_:)), name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: nil)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: nil)
    }
    
    func descriptorDidFail(_ notification: Notification)
    {
        if let descriptor = notification.object as? Descriptor,
            let key = descriptor.identifier, descriptor.error != nil
        {
            DispatchQueue.main.async { () -> Void in
                self.failedDescriptors[key] = descriptor
                self.save()
            }
        }
    }
    
    func descriptorDidCancel(_ notification: Notification)
    {
        if let descriptor = notification.object as? Descriptor,
            let key = descriptor.identifier
        {
            DispatchQueue.main.async { () -> Void in
                _ = self.removeFailedDescriptor(for: key)
            }
        }
    }
}

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
    
    private let archiver: KeyedArchiver?
    private var failedDescriptors: [String: Descriptor] = [:]

    // MARK: - Initialization
    
    deinit
    {
        self.removeObservers()
    }
    
    public init(name: String, parentFolderURL: URL)
    {
        self.archiver = type(of: self).setupArchiver(name: name, parentFolderURL: parentFolderURL)

        super.init()
        
        self.failedDescriptors = self.load()

        self.addObservers()
    }
    
    // MARK: Setup
    
    private static func setupArchiver(name: String, parentFolderURL: URL) -> KeyedArchiver?
    {
        let typeFolderURL = parentFolderURL.appendingPathComponent(name)
        
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
        
        return KeyedArchiver(basePath: typeFolderURL.path)
    }
    
    private func load() -> [String: Descriptor]
    {
        return self.archiver?.loadObject(for: type(of: self).ArchiveKey) as? [String: Descriptor] ?? [:]
    }
    
    private func save()
    {
        self.archiver?.save(object: self.failedDescriptors, key: type(of: self).ArchiveKey)
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

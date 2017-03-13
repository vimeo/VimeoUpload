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

@objc open class VideoDescriptorFailureTracker: NSObject
{
    fileprivate static let ArchiveKey = "descriptors_failed"

    // MARK: 
    
    fileprivate let archiver: KeyedArchiver
    fileprivate var failedDescriptors: [String: Descriptor] = [:]

    // MARK: - Initialization
    
    deinit
    {
        self.removeObservers()
    }
    
    public init(name: String)
    {
        self.archiver = type(of: self).setupArchiver(name: name)

        super.init()
        
        self.failedDescriptors = self.load()

        self.addObservers()
    }
    
    // MARK: Setup
    
    fileprivate static func setupArchiver(name: String) -> KeyedArchiver
    {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        var documentsURL = URL(string: documentsPath)!
        documentsURL = documentsURL.appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: documentsURL.path) == false
        {
            try! FileManager.default.createDirectory(atPath: documentsURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return KeyedArchiver(basePath: documentsURL.path)
    }
    
    fileprivate func load() -> [String: Descriptor]
    {
        return self.archiver.loadObjectForKey(type(of: self).ArchiveKey) as? [String: Descriptor] ?? [:]
    }
    
    fileprivate func save()
    {
        self.archiver.saveObject(self.failedDescriptors, key: type(of: self).ArchiveKey)
    }
    
    // MARK: Public API
    
    open func removeAllFailures()
    {
        self.failedDescriptors.removeAll()
        self.save()
    }
    
    open func removeFailedDescriptorForKey(_ key: String) -> Descriptor?
    {
        guard let descriptor = self.failedDescriptors.removeValue(forKey: key) else
        {
            return nil
        }
        
        self.save()

        return descriptor
    }
    
    open func failedDescriptorForKey(_ key: String) -> Descriptor?
    {
        return self.failedDescriptors[key]
    }
    
    // MARK: Notifications
    
    fileprivate func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(VideoDescriptorFailureTracker.descriptorDidFail(_:)), name: NSNotification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoDescriptorFailureTracker.descriptorDidCancel(_:)), name: NSNotification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: nil)
    }
    
    fileprivate func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DescriptorManagerNotification.DescriptorDidFail.rawValue), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: nil)
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
                self.removeFailedDescriptorForKey(key)
            }
        }
    }
}

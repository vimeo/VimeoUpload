//
//  DescriptorManagerTracker.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/28/15.
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

#if os(iOS)
    import UIKit
#elseif os(OSX)

#endif

// We use this class purely to report lifecycle events via print statements and local notifications [AH] 10/28/2015

open class DescriptorManagerTracker: DescriptorManagerDelegate
{
    public init() {}
    
    // MARK: DescriptorManagerDelegate
    
    @objc open func didLoadDescriptors(descriptors: Set<Descriptor>)
    {
        self.printMessageAndPostLocalNotification("Loaded \(descriptors.count)")
    }

    @objc open func didSaveDescriptors(count: Int)
    {
        self.printMessageAndPostLocalNotification("Saved \(count)")
    }

    @objc open func didFailToLoadDescriptor(error: NSError)
    {
        self.printMessageAndPostLocalNotification("Load failed: \(error.localizedDescription)")
    }
    
    @objc open func sessionDidBecomeInvalid(error: NSError)
    {
        self.printMessageAndPostLocalNotification("Session invalidated: \(error.localizedDescription)")
    }
    
    @objc open func willHandleEventsForBackgroundSession()
    {
        self.printMessageAndPostLocalNotification("Will handle background events")
    }
    
    @objc open func didFinishEventsForBackgroundSession()
    {
        self.printMessageAndPostLocalNotification("Did handle background events")
    }
    
    @objc open func downloadTaskDidFinishDownloading(task: URLSessionDownloadTask, descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Did finish downloading: \(descriptorIdentifier)")
        }
    }
    
    @objc open func taskDidComplete(task: URLSessionTask, descriptor: Descriptor, error: NSError?)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            if let error = error
            {
                self.printMessageAndPostLocalNotification("Did complete: \(descriptorIdentifier) error \(error.localizedDescription)")
            }
            else
            {
                self.printMessageAndPostLocalNotification("Did complete: \(descriptorIdentifier)")
            }
        }
    }
    
    @objc open func descriptorAdded(_ descriptor: Descriptor)
    {
        if let identifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Start \(identifier)")
        }
    }

    @objc open func descriptorDidSucceed(_ descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Success \(descriptorIdentifier)")
        }
    }

    @objc open func descriptorDidCancel(_ descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Cancellation \(descriptorIdentifier)")
        }
    }

    @objc open func descriptorDidFail(_ descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Failure \(descriptorIdentifier)")
        }
    }
    
    @objc open func descriptorForTaskNotFound(_ task: URLSessionTask)
    {
        self.printMessageAndPostLocalNotification("Descriptor for task not found")
    }
    
    // Private API
    
    fileprivate func printMessageAndPostLocalNotification(_ message: String)
    {
        print(message)
        
//        dispatch_async(dispatch_get_main_queue()) { () -> Void in
//            
//            let localNotification = UILocalNotification()
//            localNotification.timeZone = NSTimeZone.defaultTimeZone()
//            localNotification.alertBody = message
//            
//            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
//        }
    }
}

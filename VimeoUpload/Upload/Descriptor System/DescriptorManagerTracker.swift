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

class DescriptorManagerTracker: DescriptorManagerDelegate
{
    // MARK: DescriptorManagerDelegate
    
    @objc func didLoadDescriptors(descriptors descriptors: Set<Descriptor>)
    {
        self.printMessageAndPostLocalNotification("Loaded \(descriptors.count)")
    }

    @objc func didSaveDescriptors(count count: Int)
    {
        self.printMessageAndPostLocalNotification("Saved \(count)")
    }

    @objc func didFailToLoadDescriptor(error error: NSError)
    {
        self.printMessageAndPostLocalNotification("Load failed: \(error.localizedDescription)")
    }
    
    @objc func sessionDidBecomeInvalid(error error: NSError)
    {
        self.printMessageAndPostLocalNotification("Session invalidated: \(error.localizedDescription)")
    }
    
    @objc func willHandleEventsForBackgroundSession()
    {
        self.printMessageAndPostLocalNotification("Will handle background events")
    }
    
    @objc func didFinishEventsForBackgroundSession()
    {
        self.printMessageAndPostLocalNotification("Did handle background events")
    }
    
    @objc func downloadTaskDidFinishDownloading(task task: NSURLSessionDownloadTask, descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Did finish downloading: \(descriptorIdentifier)")
        }
    }
    
    @objc func taskDidComplete(task task: NSURLSessionTask, descriptor: Descriptor, error: NSError?)
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
    
    @objc func descriptorAdded(descriptor: Descriptor)
    {
        if let identifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Start \(identifier)")
        }
    }

    @objc func descriptorDidSucceed(descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Success \(descriptorIdentifier)")
        }
    }

    @objc func descriptorDidCancel(descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Cancellation \(descriptorIdentifier)")
        }
    }

    @objc func descriptorDidFail(descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.printMessageAndPostLocalNotification("Failure \(descriptorIdentifier)")
        }
    }
    
    @objc func descriptorForTaskNotFound(task: NSURLSessionTask)
    {
        self.printMessageAndPostLocalNotification("Descriptor for task not found")
    }
    
    // Private API
    
    private func printMessageAndPostLocalNotification(message: String)
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
//
//  UploadReporter.swift
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
import UIKit

// We use this class purely to report lifecycle events via print statements and local notifications [AH] 10/28/2015

class UploadReporter: DescriptorManagerDelegate
{
    // MARK: DescriptorManagerDelegate
    
    @objc func didLoadDescriptors(count count: Int)
    {
        self.sendMessage("Loaded \(count) descriptors")
    }

    @objc func didSaveDescriptors(count count: Int)
    {
        self.sendMessage("Did save \(count) descriptors")
    }

    @objc func didFailToLoadDescriptor(error error: NSError)
    {
        self.sendMessage("Did fail to load descriptor \(error.localizedDescription)")
    }
    
    @objc func sessionDidBecomeInvalid(error error: NSError)
    {
        self.sendMessage("Session invalid \(error.localizedDescription)")
    }
    
    @objc func willHandleEventsForBackgroundSession()
    {
        self.sendMessage("Will handle background events")
    }
    
    @objc func didFinishEventsForBackgroundSession()
    {
        self.sendMessage("Did handle background events")
    }
    
    @objc func downloadTaskDidFinishDownloading(task task: NSURLSessionDownloadTask, descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.sendMessage("Task download \(task.description) descriptor \(descriptorIdentifier)")
        }
    }
    
    @objc func taskDidComplete(task task: NSURLSessionTask, descriptor: Descriptor, error: NSError?)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            if let error = error
            {
                self.sendMessage("Task complete \(task.description) descriptor \(descriptorIdentifier) error \(error.localizedDescription)")
            }
            else
            {
                self.sendMessage("Task complete \(task.description) descriptor \(descriptorIdentifier)")
            }
        }
    }
    
    @objc func descriptorAdded(descriptor: Descriptor)
    {
        if let identifier = descriptor.identifier
        {
            self.sendMessage("Start \(identifier)")
        }
    }

    @objc func descriptorDidSucceed(descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.sendMessage("Success \(descriptorIdentifier)")
        }
    }
    
    @objc func descriptorDidFail(descriptor: Descriptor)
    {
        if let descriptorIdentifier = descriptor.identifier
        {
            self.sendMessage("Failure \(descriptorIdentifier)")
        }
    }
    
    @objc func descriptorForTaskNotFound(task: NSURLSessionTask)
    {
        self.sendMessage("Descriptor not found (task) \(task.description)")
    }
    
    // Private API
    
    private func sendMessage(message: String)
    {
        print(message)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            let localNotification = UILocalNotification()
            localNotification.timeZone = NSTimeZone.defaultTimeZone()
            localNotification.alertBody = message
            
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        }
    }
}
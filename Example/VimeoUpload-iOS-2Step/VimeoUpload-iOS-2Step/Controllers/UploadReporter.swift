//
//  UploadReporter.swift
//  VimeoUpload-iOS-Example
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

// We use this class purely to report lifecycle events via print statements and local notifications [AH] 10/28/2015

class UploadReporter: DescriptorManagerDelegate
{
    // MARK: DescriptorManagerDelegate
    
    func didLoadDescriptors(descriptorsCount: Int)
    {
        self.sendMessage("Loaded \(descriptorsCount) descriptors")
    }

    func willSaveDescriptors(descriptorsCount: Int)
    {
        self.sendMessage("Will save \(descriptorsCount) descriptors")
    }

    func didSaveDescriptors(descriptorsCount: Int)
    {
        self.sendMessage("Did save \(descriptorsCount) descriptors")
    }

    func sessionDidBecomeInvalid(error: NSError)
    {
        self.sendMessage("Session invalid \(error.localizedDescription)")
    }
    
    func willHandleEventsForBackgroundSession()
    {
        self.sendMessage("Will handle background events")
    }
    
    func didFinishEventsForBackgroundSession()
    {
        self.sendMessage("Did handle background events")
    }
    
    func descriptorWillStart(descriptorIdentifier: String?)
    {
        if let identifier = descriptorIdentifier
        {
            self.sendMessage("Start \(identifier)")
        }
    }
    
    func downloadTaskDidFinishDownloading(taskDescription: String?, descriptorIdentifier: String?)
    {
        if let taskDescription = taskDescription, let descriptorIdentifier = descriptorIdentifier
        {
            self.sendMessage("Task download \(taskDescription) descriptor \(descriptorIdentifier)")
        }
    }
    
    func taskDidComplete(taskDescription: String?, descriptorIdentifier: String?, error: NSError?)
    {
        if let taskDescription = taskDescription, let descriptorIdentifier = descriptorIdentifier
        {
            if let error = error
            {
                self.sendMessage("Task complete \(taskDescription) descriptor \(descriptorIdentifier) error \(error.localizedDescription)")
            }
            else
            {
                self.sendMessage("Task complete \(taskDescription) descriptor \(descriptorIdentifier)")
            }
        }
    }
    
    func descriptorDidSucceed(descriptorIdentifier: String?)
    {
        if let descriptorIdentifier = descriptorIdentifier
        {
            self.sendMessage("Success \(descriptorIdentifier)")
        }
    }
    
    func descriptorDidFail(descriptorIdentifier: String?)
    {
        if let descriptorIdentifier = descriptorIdentifier
        {
            self.sendMessage("Failure \(descriptorIdentifier)")
        }
    }
    
    func descriptorForTaskNotFound(taskDescription: String?)
    {
        if let taskDescription = taskDescription
        {
            self.sendMessage("Descriptor not found (task) \(taskDescription)")
        }
    }
    
    func descriptorForIdentifierNotFound(descriptorIdentifier: String)
    {
        self.sendMessage("Descriptor not found (id) \(descriptorIdentifier)")
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
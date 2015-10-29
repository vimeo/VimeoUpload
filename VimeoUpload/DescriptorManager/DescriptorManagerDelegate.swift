//
//  DebugMessengerProtocol.swift
//  Pegasus
//
//  Created by Hanssen, Alfie on 10/26/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

// Append the "class" keyword to allow weak references to objects that implement this protocol [AH] 10/28/2015

protocol DescriptorManagerDelegate: class
{
    func didLoadDescriptors(descriptorsCount: Int)
    
    func sessionDidBecomeInvalid(error: NSError)
    func willHandleEventsForBackgroundSession()
    func didFinishEventsForBackgroundSession()
    
    func downloadTaskDidFinishDownloading(taskDescription: String?, descriptorIdentifier: String?)
    func taskDidComplete(taskDescription: String?, descriptorIdentifier: String?, error: NSError?)

    func descriptorWillStart(descriptorIdentifier: String?)
    func descriptorDidSucceed(descriptorIdentifier: String?)
    func descriptorDidFail(descriptorIdentifier: String?)
    
    func descriptorForTaskNotFound(taskDescription: String?)
    func descriptorForIdentifierNotFound(descriptorIdentifier: String)
}
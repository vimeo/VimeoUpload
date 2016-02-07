//
//  ConnectivityManager.swift
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

@objc class ConnectivityManager: NSObject
{
    private let descriptorManager: DescriptorManager

    // MARK: 
    
    var allowsCellularUsage = true
    {
        didSet
        {
            if oldValue != allowsCellularUsage
            {
                self.updateDescriptorManagerState()
            }
        }
    }
    
    // MARK: - Initialization

    deinit
    {
        self.removeObservers()
    }
    
    init(descriptorManager: DescriptorManager)
    {
        self.descriptorManager = descriptorManager
        
        super.init()
        
        self.addObservers()
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityDidChange:", name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AFNetworkingReachabilityDidChangeNotification, object: nil)
    }
    
    func reachabilityDidChange(notification: NSNotification)
    {
        self.updateDescriptorManagerState()
    }
    
    private func updateDescriptorManagerState()
    {
        if AFNetworkReachabilityManager.sharedManager().reachable == true
        {
            if AFNetworkReachabilityManager.sharedManager().reachableViaWiFi
            {
                self.descriptorManager.resume()
            }
            else
            {
                if self.allowsCellularUsage
                {
                    self.descriptorManager.resume()
                }
                else
                {
                    self.descriptorManager.suspend()
                }
            }
        }
        else
        {
            self.descriptorManager.suspend()
        }
    }
}
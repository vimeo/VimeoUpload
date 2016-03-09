//
//  Test.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 2/6/16.
//  Copyright © 2016 Vimeo. All rights reserved.
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

@objc class VimeoDescriptorManager: NSObject // TODO: Rename this to something more appropriate [AH] 2/7/2016
{
    private let backgroundSessionManager: VimeoSessionManager
    private let connectivityManager: ConnectivityManager
    
    // MARK: 
    
    let descriptorManager: DescriptorManager
    
    // MARK:
    
    var suspended: Bool
    {
        get
        {
            return self.descriptorManager.suspended
        }
    }
    
    var allowsCellularUsage: Bool
    {
        get
        {
            return self.connectivityManager.allowsCellularUsage
        }
        set
        {
            self.connectivityManager.allowsCellularUsage = newValue
        }
    }
    
    // MARK: - Initialization
    
    init(name: String, backgroundSessionIdentifier: String, descriptorManagerDelegate: DescriptorManagerDelegate? = nil, authTokenBlock: AuthTokenBlock)
    {
        self.backgroundSessionManager = VimeoSessionManager.backgroundSessionManager(identifier: backgroundSessionIdentifier, authTokenBlock: authTokenBlock)
        self.descriptorManager = DescriptorManager(sessionManager: self.backgroundSessionManager, name: name, delegate: descriptorManagerDelegate)
        self.connectivityManager = ConnectivityManager(descriptorManager: self.descriptorManager)
        
        super.init()
    }
    
    // MARK: Public API - Background Session
    
    func applicationDidFinishLaunching()
    {
        // Do nothing at the moment
    }
    
    func handleEventsForBackgroundURLSession(identifier identifier: String, completionHandler: VoidClosure) -> Bool
    {
        return self.descriptorManager.handleEventsForBackgroundURLSession(identifier: identifier, completionHandler: completionHandler)
    }
}
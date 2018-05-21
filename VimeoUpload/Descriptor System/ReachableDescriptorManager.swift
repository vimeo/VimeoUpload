//
//  ReachableDescriptorManager.swift
//  VimeoUpload
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
import VimeoNetworking

@objc public class ReachableDescriptorManager: DescriptorManager, ConnectivityManagerDelegate
{
    private let connectivityManager = ConnectivityManager()
    
    // MARK:
    
    public var allowsCellularUsage: Bool
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
    
    public init(name: String, parentFolderURL: URL, backgroundSessionIdentifier: String, sharedContainerIdentifier: String? = nil, descriptorManagerDelegate: DescriptorManagerDelegate? = nil, accessTokenProvider: @escaping VimeoRequestSerializer.AccessTokenProvider, apiVersion: String)
    {
        let backgroundSessionManager: VimeoSessionManager
        
        if let sharedContainerIdentifier = sharedContainerIdentifier
        {
            backgroundSessionManager = VimeoSessionManager.backgroundSessionManager(identifier: backgroundSessionIdentifier, baseUrl: VimeoBaseURL, sharedContainerIdentifier: sharedContainerIdentifier, accessTokenProvider: accessTokenProvider, apiVersion: apiVersion)
        }
        else
        {
            backgroundSessionManager = VimeoSessionManager.backgroundSessionManager(identifier: backgroundSessionIdentifier, baseUrl: VimeoBaseURL, accessTokenProvider: accessTokenProvider, apiVersion: apiVersion)
        }
        
        super.init(sessionManager: backgroundSessionManager, name: name, parentFolderURL: parentFolderURL, delegate: descriptorManagerDelegate)
        
        self.connectivityManager.delegate = self
    }
    
    // MARK: Public API - Background Session
    
    public func applicationDidFinishLaunching()
    {
        // No-op
    }
    
    // MARK: ConnectivityManagerDelegate

    func suspend(connectivityManager: ConnectivityManager)
    {
        self.suspend()
    }
    
    func resume(connectivityManager: ConnectivityManager)
    {
        self.resume()
    }
}

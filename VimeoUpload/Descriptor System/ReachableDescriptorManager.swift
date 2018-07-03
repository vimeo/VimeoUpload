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
    
    /// Initializes a reachable descriptor manager object.
    ///
    /// - Parameters:
    ///   - name: The name of the descriptor manager.
    ///   - archivePrefix: The prefix of the archive file. You pass in the
    ///   prefix if you want to keep track of multiple archive files. By
    ///   default, it has the value of `nil`.
    ///   - shouldLoadArchive: A Boolean value that determines if the
    ///   descriptor manager should load descriptors from the archive file
    ///   upon instantiating. By default, this argument has the value of
    ///   `true`.
    ///   - documentsFolderURL: The Documents folder's URL of the folder in
    ///   which the upload description will be stored. That folder has the
    ///   same name as the first argument.
    ///   - backgroundSessionIdentifier: An ID of the background upload
    ///   session.
    ///   - sharedContainerIdentifier: An ID of a shared sandbox. By default
    ///   this value is `nil`, but if `VimeoUpload` is used in an app
    ///   extension, this value must be set.
    ///   - descriptorManagerDelegate: A delegate object of this descriptor
    ///   manager.
    ///   - accessTokenProvider: A closure that provides an authenticated
    ///   token. Any upload needs this token in order to work properly.
    ///   - apiVersion: The API version to use.
    /// - Returns: `nil` if the keyed archiver cannot load descriptors' archive.
    public init?(name: String,
                 archivePrefix: String? = nil,
                 shouldLoadArchive: Bool = true,
                 documentsFolderURL: URL,
                 backgroundSessionIdentifier: String,
                 sharedContainerIdentifier: String? = nil,
                 descriptorManagerDelegate: DescriptorManagerDelegate? = nil,
                 accessTokenProvider: @escaping VimeoRequestSerializer.AccessTokenProvider,
                 apiVersion: String)
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
        
        super.init(sessionManager: backgroundSessionManager,
                   name: name,
                   archivePrefix: archivePrefix,
                   shouldLoadArchive: shouldLoadArchive,
                   documentsFolderURL: documentsFolderURL,
                   delegate: descriptorManagerDelegate)
        
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

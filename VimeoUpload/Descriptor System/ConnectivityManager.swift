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
import VimeoNetworking

protocol ConnectivityManagerDelegate: AnyObject
{
    func suspend(connectivityManager: ConnectivityManager)
    func resume(connectivityManager: ConnectivityManager)
}

@objc class ConnectivityManager: NSObject
{
    weak var delegate: ConnectivityManagerDelegate?
    
    private let reachabilityChangedNotificaton = Notification.Name(
        rawValue: NetworkingNotification.reachabilityDidChange.rawValue
    )
    
    var allowsCellularUsage = true
    {
        didSet
        {
            if oldValue != allowsCellularUsage
            {
                self.updateState()
            }
        }
    }
    
    // MARK: - Initialization

    deinit
    {
        self.removeObservers()
    }
    
    override init()
    {
        super.init()
        
        self.addObservers()
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ConnectivityManager.reachabilityDidChange(_:)),
            name: reachabilityChangedNotificaton, object: nil
        )
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(
            self,
            name: reachabilityChangedNotificaton,
            object: nil
        )
    }
    
    @objc func reachabilityDidChange(_ notification: Notification)
    {
        self.updateState()
    }
    
    private func updateState()
    {
        guard VimeoReachabilityProvider.isReachable else {
            self.delegate?.suspend(connectivityManager: self)
            return
        }

        if VimeoReachabilityProvider.isReachableOnEthernetOrWiFi == true
        {
            self.delegate?.resume(connectivityManager: self)
        }
        else
        {
            if self.allowsCellularUsage
            {
                self.delegate?.resume(connectivityManager: self)
            }
            else
            {
                self.delegate?.suspend(connectivityManager: self)
            }
        }
    }
}

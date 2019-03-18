//
//  AppDelegate.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/29/15.
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

import UIKit
import AFNetworking

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        NSKeyedUnarchiver.setLegacyClassNameMigrations()
        
        AFNetworkReachabilityManager.shared().startMonitoring()
        NewVimeoUploader.sharedInstance?.applicationDidFinishLaunching() // Ensure init is called on launch

        let settings = UIUserNotificationSettings(types: .alert, categories: nil)
        application.registerUserNotificationSettings(settings)
        
        let viewController = MyVideosViewController(nibName: MyVideosViewController.NibName, bundle:Bundle.main)
        let navigationController = UINavigationController(rootViewController: viewController)
        
        let frame = UIScreen.main.bounds
        self.window = UIWindow(frame: frame)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
    {
        guard let descriptorManager = NewVimeoUploader.sharedInstance?.descriptorManager else
        {
            return
        }
        
        if descriptorManager.canHandleEventsForBackgroundURLSession(withIdentifier: identifier)
        {
            descriptorManager.handleEventsForBackgroundURLSession(completionHandler: completionHandler)
        }
    }
}


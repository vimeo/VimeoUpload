//
//  AppDelegate.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 10/14/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        application.registerUserNotificationSettings(settings)
        
        let viewController = CameraRollViewController(nibName:"CameraRollViewController", bundle:NSBundle.mainBundle())
        let navigationController = UINavigationController(rootViewController: viewController)
        
        let frame = UIScreen.mainScreen().bounds
        self.window = UIWindow(frame: frame)
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        return true
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void)
    {
        if UploadManager.sharedInstance.descriptorManager.handleEventsForBackgroundURLSession(identifier, completionHandler: completionHandler) == false
        {
            // Handle events elsewhere
        }
    }
}


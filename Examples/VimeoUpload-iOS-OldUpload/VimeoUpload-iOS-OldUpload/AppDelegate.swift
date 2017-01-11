//
//  AppDelegate.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/14/15.
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
import Photos
import AFNetworking

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        AFNetworkReachabilityManager.sharedManager().startMonitoring()
        OldVimeoUploader.sharedInstance.applicationDidFinishLaunching() // Ensure init is called on launch

        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        application.registerUserNotificationSettings(settings)

        let cameraRollViewController = CameraRollViewController(nibName: BaseCameraRollViewController.NibName, bundle:NSBundle.mainBundle())
        let uploadsViewController = UploadsViewController(nibName: UploadsViewController.NibName, bundle:NSBundle.mainBundle())
        
        let cameraNavController = UINavigationController(rootViewController: cameraRollViewController)
        cameraNavController.tabBarItem.title = "Camera Roll"

        let uploadsNavController = UINavigationController(rootViewController: uploadsViewController)
        uploadsNavController.tabBarItem.title = "Uploads"
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [cameraNavController, uploadsNavController]
        tabBarController.selectedIndex = 1
        
        let frame = UIScreen.mainScreen().bounds
        self.window = UIWindow(frame: frame)
        self.window?.rootViewController = tabBarController
        self.window?.makeKeyAndVisible()
        
        // Adding this here as work-around to stop system notifications from fuxing with
        // unit tests, which launch the app, and hang until the notification is addressed.
        if NSClassFromString("XCTestCase") == nil
        {
            self.requestCameraRollAccessIfNecessary()
        }
        
        return true
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void)
    {
        if OldVimeoUploader.sharedInstance.descriptorManager.handleEventsForBackgroundURLSession(identifier: identifier, completionHandler: completionHandler) == false
        {
            assertionFailure("Unhandled background events")
        }
    }
    
    private func requestCameraRollAccessIfNecessary()
    {
        PHPhotoLibrary.requestAuthorization { status in
            switch status
            {
            case .Authorized:
                print("Camera roll access granted")
            case .Restricted:
                print("Unable to present camera roll. Camera roll access restricted.")
            case .Denied:
                print("Unable to present camera roll. Camera roll access denied.")
            default:
                // place for .NotDetermined - in this callback status is already determined so should never get here
                break
            }
        }
    }
}


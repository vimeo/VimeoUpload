//
//  MyVideosViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/1/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

class MyVideosViewController: UIViewController, CameraRollViewControllerDelegate
{
    static let NibName = "MyVideosViewController"
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = "My Videos"
    }
    
    // MARK: Actions
    
    @IBAction func didTapUpload(sender: UIButton)
    {
        let viewController = NewCameraRollViewController(nibName: CameraRollViewController.NibName, bundle:NSBundle.mainBundle())
        viewController.delegate = self
        viewController.sessionManager = UploadManager.sharedInstance.sessionManager

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.view.backgroundColor = UIColor.whiteColor()
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: CameraRollViewControllerDelegate
    
    func cameraRollViewControllerDidFinish(viewController: CameraRollViewController, result: CameraRollViewControllerResult)
    {
        let settingsViewController = NewVideoSettingsViewController(nibName: VideoSettingsViewController.NibName, bundle:NSBundle.mainBundle())
        settingsViewController.input = result
        
        viewController.navigationController?.pushViewController(settingsViewController, animated: true)
    }    
}

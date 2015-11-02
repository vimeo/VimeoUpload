//
//  MyVideosViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/1/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

class MyVideosViewController: UIViewController
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
        let viewController = CameraRollViewController(nibName: CameraRollViewController.NibName, bundle:NSBundle.mainBundle())
        
        let navigationController = UINavigationController(rootViewController: viewController)
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
}

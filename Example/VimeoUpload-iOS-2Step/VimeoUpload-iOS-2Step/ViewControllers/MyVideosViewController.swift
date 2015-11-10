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
        navigationController.view.backgroundColor = UIColor.whiteColor()
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
//     MARK: KVO
//
//    private func addObservers()
//    {
//        self.uploadDescriptor?.addObserver(self, forKeyPath: VideoSettingsViewController.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.uploadProgressKVOContext)
//    }
//    
//    private func removeObservers()
//    {
//        self.uploadDescriptor?.removeObserver(self, forKeyPath: VideoSettingsViewController.ProgressKeyPath, context: &self.uploadProgressKVOContext)
//    }
//    
//    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
//    {
//        if let keyPath = keyPath
//        {
//            switch (keyPath, context)
//            {
//            case(VideoSettingsViewController.ProgressKeyPath, &self.uploadProgressKVOContext):
//                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
//                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    print("Outer progress: \(progress)")
//                })
//                
//            default:
//                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
//            }
//        }
//        else
//        {
//            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
//        }
//    }
}

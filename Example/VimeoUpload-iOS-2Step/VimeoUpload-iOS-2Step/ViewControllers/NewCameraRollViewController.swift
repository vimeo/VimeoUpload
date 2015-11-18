//
//  NewCameraRollViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Hanssen, Alfie on 11/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

class NewCameraRollViewController: CameraRollViewController
{
    override func setupNavigationBar()
    {
        super.setupNavigationBar()
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "didTapCancel:")
        self.navigationItem.leftBarButtonItem = cancelItem
    }
}

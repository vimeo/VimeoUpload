//
//  MyVideosViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/1/15.
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
}

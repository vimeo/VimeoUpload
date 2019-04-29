//
//  CameraRollViewController.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/14/15.
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
import UIKit
import VimeoUpload

class CameraRollViewController: BaseCameraRollViewController
{
    override func viewDidLoad()
    {
        self.sessionManager = NewVimeoUploader.sharedInstance?.foregroundSessionManager

        super.viewDidLoad()
    }
    
    // MARK: Overrides
    
    override func setupNavigationBar()
    {
        super.setupNavigationBar()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(CameraRollViewController.didTapCancel(_:)))
    }
    
    override func didSelect(_ asset: VIMPHAsset)
    {
        let viewController = VideoSettingsViewController(asset: asset)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: Actions
    
    @objc func didTapCancel(_ sender: UIBarButtonItem)
    {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

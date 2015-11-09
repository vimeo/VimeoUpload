//
//  VideoSettingsViewController.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 10/16/15.
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
import AVFoundation

class VideoSettingsViewController: UIViewController, UITextFieldDelegate
{
    static let NibName = "VideoSettingsViewController"
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    var uploadPrepOperation: UploadPrepOperation?
    
    private var uploadDescriptor: UploadDescriptor?

    private static let ProgressKeyPath = "uploadProgress"
    private var uploadProgressKVOContext = UInt8()
    
    // MARK: Lifecycle
    
    deinit
    {
        self.removeObservers()
        self.uploadPrepOperation?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.uploadPrepOperation != nil, "self.uploadPrepOperation cannot be nil")
        
        self.edgesForExtendedLayout = .None
        
        self.setupNavigationBar()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // TODO: Is this going to be called if we show a childViewController or an alert?
        
        if self.isMovingFromParentViewController() == true // User tapped back button or post button
        {
            self.uploadPrepOperation?.cancel()
        }
    }
    
    // MARK: Setup
    
    private func setupNavigationBar()
    {
        self.title = "Video Settings"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.Done, target: self, action: "didTapPost:")
    }
    
    // MARK: Actions

    func didTapPost(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        self.descriptionTextView.becomeFirstResponder()
        
        return false
    }
    
    // MARK: Private API
        
    private func uploadFile(url: NSURL)
    {
        let videoSettings = VideoSettings(title: "hey!!", description: nil, privacy: "goo", users: nil)
        self.uploadDescriptor = UploadDescriptor(url: url, videoSettings: videoSettings)
        self.uploadDescriptor!.identifier = "\(url.absoluteString.hash)"
            
        self.addObservers()
        
        try! UploadManager.sharedInstance.descriptorManager.addDescriptor(self.uploadDescriptor!)
    }
    
    // MARK: KVO
        
    private func addObservers()
    {
        self.uploadDescriptor?.addObserver(self, forKeyPath: VideoSettingsViewController.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.uploadProgressKVOContext)
    }
    
    private func removeObservers()
    {
        self.uploadDescriptor?.removeObserver(self, forKeyPath: VideoSettingsViewController.ProgressKeyPath, context: &self.uploadProgressKVOContext)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(VideoSettingsViewController.ProgressKeyPath, &self.uploadProgressKVOContext):
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    print("Outer progress: \(progress)")
                })
                
            default:
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
        }
        else
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

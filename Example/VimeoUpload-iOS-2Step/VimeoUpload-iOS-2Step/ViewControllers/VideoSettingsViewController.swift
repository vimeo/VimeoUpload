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

typealias VideoSettingsViewControllerInput = (me: VIMUser, phAssetContainer: PHAssetContainer)

class VideoSettingsViewController: UIViewController, UITextFieldDelegate
{
    static let NibName = "VideoSettingsViewController"
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    var input: VideoSettingsViewControllerInput?
    private var operation: VideoSettingsOperation?
    private var descriptor: UploadDescriptor?

    private static let ProgressKeyPath = "uploadProgress"
    private var uploadProgressKVOContext = UInt8()
    
    // MARK: Lifecycle
    
    deinit
    {
        self.operation?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.input != nil, "self.input cannot be nil")
        
        self.edgesForExtendedLayout = .None
        
        self.setupNavigationBar()
        
        let me = self.input!.me
        let phAssetContainer = self.input!.phAssetContainer
        self.setupOperation(me, phAssetContainer: phAssetContainer)
    }
    
    // MARK: Setup
    
    private func setupNavigationBar()
    {
        self.title = "Video Settings"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.Done, target: self, action: "didTapPost:")
    }
    
    private func setupOperation(me: VIMUser, phAssetContainer: PHAssetContainer)
    {
        let operation = VideoSettingsOperation(me: me, phAssetContainer: phAssetContainer)
        self.setOperationBlocks(operation)
        self.operation = operation
        self.operation?.start()
    }
    
    private func setOperationBlocks(operation: VideoSettingsOperation)
    {
        operation.downloadProgressBlock = { (progress: Double) -> Void in
            print("Download progress (settings): \(progress)")
        }
        operation.exportProgressBlock = { (progress: Double) -> Void in
            print("Export progress (settings): \(progress)")
        }
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.cancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    print("Video settings operation error: \(error)")
                }
                else
                {
                    print("Video settings operation complete! \(operation.result!)")
                    strongSelf.startUpload(operation.result!)
                }
            })
        }
    }
    
    // MARK: Actions

    func didTapPost(sender: UIBarButtonItem)
    {
        if let error = self.operation?.error
        {
            self.presentOperationErrorAlert(error)
        }
        else if let error = self.descriptor?.error
        {
            self.presentDescriptorErrorAlert(error)
        }
        else if self.operation?.state == .Executing
        {
            self.activityIndicatorView.startAnimating()
        }
        else if self.descriptor?.state == .Executing
        {
            self.activityIndicatorView.startAnimating()
        }
        else
        {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        self.descriptionTextView.becomeFirstResponder()
        
        return false
    }
    
    // MARK: UI Presentation
    
    private func presentOperationErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Operation Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.navigationController?.popViewControllerAnimated(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            let me = strongSelf.operation!.me
            let phAssetContainer = strongSelf.operation!.phAssetContainer
            strongSelf.setupOperation(me, phAssetContainer: phAssetContainer)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentDescriptorErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Descriptor Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.navigationController?.popViewControllerAnimated(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            
            guard let _ = self else
            {
                return
            }
            
            // TODO: do something to try the descriptor again
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: Private API
        
    private func startUpload(url: NSURL)
    {
        let videoSettings = VideoSettings(title: "hey!!", description: nil, privacy: "goo", users: nil)
        self.descriptor = UploadDescriptor(url: url, videoSettings: videoSettings)
        self.descriptor!.identifier = "\(url.absoluteString.hash)"
        
        try! UploadManager.sharedInstance.descriptorManager.addDescriptor(self.descriptor!)
    }    
}

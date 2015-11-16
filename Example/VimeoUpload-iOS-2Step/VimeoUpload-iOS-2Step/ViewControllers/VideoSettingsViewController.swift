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
    private var videoSettings: VideoSettings?
    
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
        self.startOperation()
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
                    if let _ = strongSelf.videoSettings
                    {
                        strongSelf.activityIndicatorView.stopAnimating()
                        strongSelf.presentOperationErrorAlert(error)
                    }
                }
                else
                {
                    strongSelf.startUpload(operation.result!)
                    
                    if let _ = strongSelf.videoSettings
                    {
                        strongSelf.activityIndicatorView.stopAnimating()
                        strongSelf.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            })
        }
    }
    
    // MARK: Actions

    // 4-step upload
    func didTapPost(sender: UIBarButtonItem)
    {
        let title = self.titleTextField.text
        let description = self.descriptionTextView.text
        self.videoSettings = VideoSettings(title: title, description: description, privacy: "nobody", users: nil)
        
        if self.operation?.state == .Executing
        {
            self.activityIndicatorView.startAnimating() // Listen for operation completion, dismiss
        }
        else if let error = self.operation?.error
        {
            self.presentOperationErrorAlert(error)
        }
        else if let descriptor = self.descriptor
        {
            if descriptor.state == .Executing
            {
                // TODO: 2-step upload
                // if create is in progress, show activity indicator and listen for create completion
                // if create is complete, add video settings and dismiss the view controller

                // 4-step upload
                descriptor.videoSettings = self.videoSettings // TODO: We need to somehow save the descriptor list after setting this
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            else
            {
                if let error = descriptor.error
                {
                    self.presentDescriptorErrorAlert(error)
                }
                else
                {
                    self.applyVideoSettings()
                }
            }
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
            self?.startOperation()
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
            // We start from the beginning (with the operation instead of the descriptor), 
            // Because the exported file was deleted when the upload descriptor failed,
            // We delete it because leaving it up to the API consumer to delete seems a little risky
            self?.startOperation()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentVideoSettingsErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Video Settings Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.navigationController?.popViewControllerAnimated(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.applyVideoSettings()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: Private API
    
    private func applyVideoSettings()
    {
        self.activityIndicatorView.startAnimating()

        let videoUri = self.descriptor!.videoUri!
        let videoSettings = self.videoSettings!
        
        do
        {
            let task = try UploadManager.sharedInstance.sessionManager.videoSettingsDataTask(videoUri: videoUri, videoSettings: videoSettings, completionHandler: { [weak self] (video, error) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    
                    self?.activityIndicatorView.stopAnimating()

                    if let error = error
                    {
                        self?.presentVideoSettingsErrorAlert(error)
                    }
                    else
                    {
                        self?.dismissViewControllerAnimated(true, completion: nil)
                    }
                })
                
            })
            task.resume()
        }
        catch let error as NSError
        {
            self.activityIndicatorView.stopAnimating()
            self.presentVideoSettingsErrorAlert(error)
        }
    }
    
    private func startOperation()
    {
        let me = self.input!.me
        let phAssetContainer = self.input!.phAssetContainer
        self.setupOperation(me, phAssetContainer: phAssetContainer)
    }
    
    private func startUpload(url: NSURL)
    {
        self.descriptor = UploadDescriptor(url: url)
        self.descriptor?.identifier = "\(url.absoluteString.hash)"
        self.descriptor?.videoSettings = self.videoSettings

        UploadManager.sharedInstance.descriptorManager.addDescriptor(self.descriptor!)
    }    
}

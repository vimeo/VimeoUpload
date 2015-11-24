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

class VideoSettingsViewController: UIViewController, UITextFieldDelegate
{
    static let UploadInitiatedNotification = "VideoSettingsViewControllerUploadInitiatedNotification"
    static let NibName = "VideoSettingsViewController"
    private static let PreUploadViewPrivacy = "pre_upload"
    
    // MARK: 
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK:
    
    var input: CameraRollViewControllerResult?
    
    // MARK:
    
    private var operation: ConcurrentOperation?

    // MARK:
    
    private var url: NSURL?
    private var uploadTicket: VIMUploadTicket?
    private var videoSettings: VideoSettings?

    // MARK:

    private var hasTappedUpload: Bool
    {
        get
        {
            return self.videoSettings != nil
        }
    }
    
    // MARK: Lifecycle
    
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
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "didTapCancel:")

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload", style: UIBarButtonItemStyle.Done, target: self, action: "didTapUpload:")
    }

    private func startOperation()
    {
        self.operation = self.buildOperation()
        self.operation?.start()
    }
    
    private func startUpload()
    {
        // TODO: handle retry
        
        let url = self.url!
        let uploadTicket = self.uploadTicket!
        
        UploadManager.sharedInstance.uploadVideoWithUrl(url, uploadTicket: uploadTicket)
    }
    
    private func buildOperation() -> ConcurrentOperation
    {
        let me = self.input!.me
        let phAssetContainer = self.input!.phAssetContainer
        let sessionManager = ForegroundSessionManager.sharedInstance
        let videoSettings = self.videoSettings
        
        let operation = SimplePrepareUploadOperation(me: me, phAssetContainer: phAssetContainer, sessionManager: sessionManager, videoSettings: videoSettings)
        
        operation.downloadProgressBlock = { (progress: Double) -> Void in
            print("Download progress (settings): \(progress)") // TODO: Dispatch to main thread
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
                
                if operation.error == nil
                {
                    strongSelf.url = operation.url!
                    strongSelf.uploadTicket = operation.uploadTicket!
                    strongSelf.startUpload()
                }

                if strongSelf.hasTappedUpload == true
                {
                    if let error = operation.error
                    {
                        strongSelf.activityIndicatorView.stopAnimating()
                        strongSelf.presentOperationErrorAlert(error)
                    }
                    else
                    {
                        if let video = strongSelf.uploadTicket?.video, let viewPrivacy = video.privacy?.view where viewPrivacy != VideoSettingsViewController.PreUploadViewPrivacy
                        {
                            NSNotificationCenter.defaultCenter().postNotificationName(VideoSettingsViewController.UploadInitiatedNotification, object: video)

                            strongSelf.activityIndicatorView.stopAnimating()
                            strongSelf.dismissViewControllerAnimated(true, completion: nil)
                        }
                        else
                        {
                            strongSelf.applyVideoSettings()
                        }
                    }
                }
            })
        }
        
        return operation
    }

    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
        self.operation?.cancel()
        self.activityIndicatorView.stopAnimating()
        self.navigationController?.popViewControllerAnimated(true)
    
        // TODO: test this
        
        if let videoUri = self.uploadTicket?.video?.uri
        {
            UploadManager.sharedInstance.deleteVideoWithUri(videoUri)
        }
    }

    func didTapUpload(sender: UIBarButtonItem)
    {
        let title = self.titleTextField.text
        let description = self.descriptionTextView.text
        self.videoSettings = VideoSettings(title: title, description: description, privacy: "nobody", users: nil)
     
        let operation = self.operation as? SimplePrepareUploadOperation

        if operation?.state == .Executing
        {
            operation?.videoSettings = self.videoSettings

            self.activityIndicatorView.startAnimating() // Listen for operation completion, dismiss
        }
        else if let error = operation?.error
        {
            self.presentOperationErrorAlert(error)
        }
        else
        {
            if let video = self.uploadTicket?.video, let viewPrivacy = video.privacy?.view where viewPrivacy != VideoSettingsViewController.PreUploadViewPrivacy
            {
                NSNotificationCenter.defaultCenter().postNotificationName(VideoSettingsViewController.UploadInitiatedNotification, object: video)
                
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            else
            {
                self.activityIndicatorView.startAnimating()
                self.applyVideoSettings()
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
            self?.activityIndicatorView.startAnimating()
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
            self?.activityIndicatorView.startAnimating()
            self?.applyVideoSettings()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: Private API
    
    private func applyVideoSettings()
    {
        let videoUri = self.uploadTicket!.video!.uri!
        let videoSettings = self.videoSettings!
        
        do
        {
            // TODO: should this be cancelable?
            
            let task = try ForegroundSessionManager.sharedInstance.videoSettingsDataTask(videoUri: videoUri, videoSettings: videoSettings, completionHandler: { [weak self] (video, error) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    
                    self?.activityIndicatorView.stopAnimating()
                    
                    if let error = error
                    {
                        self?.presentVideoSettingsErrorAlert(error)
                    }
                    else
                    {
                        NSNotificationCenter.defaultCenter().postNotificationName(VideoSettingsViewController.UploadInitiatedNotification, object: video)
                        
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
}

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
    static let NibName = "VideoSettingsViewController"
    
    // MARK: 
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK:
    
    var input: CameraRollViewControllerResult?
    
    // MARK:
    
    private var operation: ConcurrentOperation?
    private var descriptor: Descriptor?

    // MARK:
    
    private var url: NSURL?
    private var videoSettings: VideoSettings?

    // MARK:

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
        self.descriptor = self.buildDescriptor()
        UploadManager.sharedInstance.descriptorManager.addDescriptor(self.descriptor!)
    }
    
    private func buildOperation() -> ConcurrentOperation
    {
        let me = self.input!.me
        let phAssetContainer = self.input!.phAssetContainer
        let operation = CompositeCloudExportOperation(me: me, phAssetContainer: phAssetContainer)
        
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
                    strongSelf.url = operation.result!
                }
                
                if strongSelf.hasTappedUpload() == true
                {
                    if let error = operation.error
                    {
                        strongSelf.activityIndicatorView.stopAnimating()
                        strongSelf.presentOperationErrorAlert(error)
                    }
                    else
                    {
                        strongSelf.startUpload()
                        
                        strongSelf.activityIndicatorView.stopAnimating()
                        strongSelf.dismissViewControllerAnimated(true, completion: nil)
                    }
                }
            })
        }
        
        return operation
    }
    
    private func buildDescriptor() -> Descriptor
    {
        let descriptor = UploadDescriptor(url: self.url!, videoSettings: self.videoSettings)
        descriptor.identifier = "\(self.url!.absoluteString.hash)"
        
        return descriptor
    }

    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
        self.operation?.cancel()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func didTapUpload(sender: UIBarButtonItem)
    {
        let operation = self.operation as? CompositeCloudExportOperation
        
        let title = self.titleTextField.text
        let description = self.descriptionTextView.text
        self.videoSettings = VideoSettings(title: title, description: description, privacy: "nobody", users: nil)
        
        if operation?.state == .Executing
        {
            self.activityIndicatorView.startAnimating() // Listen for operation completion, dismiss
        }
        else if let error = operation?.error
        {
            self.presentOperationErrorAlert(error)
        }
        else
        {
            self.startUpload()
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
            self?.navigationController?.dismissViewControllerAnimated(true, completion: nil)
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
            self?.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            // We start from the beginning (with the operation instead of the descriptor), 
            // Because the exported file was deleted when the upload descriptor failed,
            // We delete it because leaving it up to the API consumer to delete seems a little risky
            self?.startOperation()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Private API
    
    private func hasTappedUpload() -> Bool
    {
        return self.videoSettings != nil
    }
}

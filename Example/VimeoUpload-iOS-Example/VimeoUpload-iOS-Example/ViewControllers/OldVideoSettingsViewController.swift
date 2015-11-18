//
//  OldVideoSettingsViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Hanssen, Alfie on 11/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

class OldVideoSettingsViewController: VideoSettingsViewController
{
    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
        self.operation?.cancel()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Overrides
    
    override func setupNavigationBar()
    {
        super.setupNavigationBar()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "didTapCancel:")
    }

    override func buildOperation() -> ConcurrentOperation
    {
        let me = self.input!.me
        let phAssetContainer = self.input!.phAssetContainer
        let operation = VideoSettingsOperation(me: me, phAssetContainer: phAssetContainer)
        
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
                    strongSelf.url = operation.result!
                    
                    if let _ = strongSelf.videoSettings
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
    
    override func buildDescriptor() -> Descriptor?
    {
        let descriptor = UploadDescriptor(url: self.url!, videoSettings: self.videoSettings)
        descriptor.identifier = "\(self.url!.absoluteString.hash)"
        
        return descriptor
    }
    
    override func didTapUpload(sender: UIBarButtonItem)
    {
        let operation = self.operation as? VideoSettingsOperation
        
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
}

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
    override func viewDidLoad()
    {
        super.viewDidLoad()

    }
    
    // MARK: Overrides
    
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
                    
                    if let videoSettings = strongSelf.videoSettings
                    {
                        strongSelf.startUpload(operation.result!, videoSettings: videoSettings)
                        
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
        let descriptor = UploadDescriptor(url: url, videoSettings: videoSettings)
        descriptor.identifier = "\(url.absoluteString.hash)"
        
        return descriptor
    }
    
    override func didTapUpload(sender: UIBarButtonItem)
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
        else
        {
            self.startUpload(self.url!, videoSettings: self.videoSettings)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

//
//  NewVideoSettingsViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Hanssen, Alfie on 11/18/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

class NewVideoSettingsViewController: VideoSettingsViewController
{
    // MARK: Overrides
    
    override func buildOperation() -> ConcurrentOperation?
    {
        assertionFailure("Subclasses must override this method")
        
        return nil
    }
    
    override func buildDescriptor() -> Descriptor?
    {
        assertionFailure("Subclasses must override this method")
        
        return nil
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
            // TODO: somethign
        }
    }
    
    // MARK: UI Presentation

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
        let descriptor = self.descriptor as? UploadDescriptor

        self.activityIndicatorView.startAnimating()
        
        let videoUri = descriptor!.videoUri!
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

}

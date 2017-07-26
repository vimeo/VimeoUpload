//
//  VideoSettingsViewController.swift
//  VimeoUpload
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
import Photos
import AssetsLibrary
import VimeoNetworking
import VimeoUpload

/*
    This viewController provides an interface for the user to modify a video's settings (title, description, privacy) before upload.

    Upon load it starts a composite operation that downloads the asset from iCloud if necessary, exports a copy of it to disk, and creates the video object / upload ticket. This occurs in the background without the user being aware that it's happening. So that we can get a jump start on uploading. When these steps complete we start the upload itself.

    When the user taps the "upload" button we display progress/activity indicators if the above steps have not completed. And we then apply the video's settings set by the user. 

    [AH] 12/03/2015
*/

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
    
    var input: UploadUserAndCameraRollAsset?
    
    // MARK:
    
    private var operation: ConcurrentOperation?
    private var task: URLSessionDataTask?
    
    // MARK:
    
    private var url: URL?
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
    
    deinit
    {
        // Do not cancel operation, it will delete the source file
        self.task?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.input != nil, "self.input cannot be nil")
        
        self.edgesForExtendedLayout = []
        
        self.setupNavigationBar()
        self.setupAndStartOperation()
    }
    
    // MARK: Setup
    
    private func setupNavigationBar()
    {
        self.title = "Video Settings"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(VideoSettingsViewController.didTapCancel(_:)))

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload", style: UIBarButtonItemStyle.done, target: self, action: #selector(VideoSettingsViewController.didTapUpload(_:)))
    }

    private func setupAndStartOperation()
    {
        let me = self.input!.user
        let cameraRollAsset = self.input!.cameraRollAsset
        let sessionManager = NewVimeoUploader.sharedInstance.foregroundSessionManager
        let videoSettings = self.videoSettings
        
        let phAsset = cameraRollAsset.phAsset
        let operation = PHAssetCloudExportQuotaCreateOperation(me: me, phAsset: phAsset, sessionManager: sessionManager, videoSettings: videoSettings)
        
        operation.downloadProgressBlock = { (progress: Double) -> Void in
            print(String(format: "Download progress: %.2f", progress)) // TODO: Dispatch to main thread
        }
        
        operation.exportProgressBlock = { (exportSession: AVAssetExportSession, progress: Double) -> Void in
            print(String(format: "Export progress: %.2f", progress))
        }
        
        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
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
                        strongSelf.presentOperationErrorAlert(with: error)
                    }
                    else
                    {
                        if let video = strongSelf.uploadTicket?.video, let viewPrivacy = video.privacy?.view, viewPrivacy != type(of: strongSelf).PreUploadViewPrivacy
                        {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: VideoSettingsViewController.UploadInitiatedNotification), object: video)
                            
                            strongSelf.activityIndicatorView.stopAnimating()
                            strongSelf.dismiss(animated: true, completion: nil)
                        }
                        else
                        {
                            strongSelf.applyVideoSettings()
                        }
                    }
                }
            })
        }
        
        self.operation = operation
        self.operation?.start()
    }
    
    private func startUpload()
    {
        let url = self.url!
        let uploadTicket = self.uploadTicket!
        let assetIdentifier = self.input!.cameraRollAsset.identifier
        
        let descriptor = UploadDescriptor(url: url, uploadTicket: uploadTicket)
        descriptor.identifier = assetIdentifier
        
        NewVimeoUploader.sharedInstance.uploadVideo(descriptor: descriptor)
    }

    // MARK: Actions
    
    func didTapCancel(_ sender: UIBarButtonItem)
    {
        self.operation?.cancel()
        self.activityIndicatorView.stopAnimating()
        _ = self.navigationController?.popViewController(animated: true)
        
        if let videoUri = self.uploadTicket?.video?.uri
        {
            NewVimeoUploader.sharedInstance.cancelUpload(videoUri: videoUri)
        }
    }

    func didTapUpload(_ sender: UIBarButtonItem)
    {
        let title = self.titleTextField.text
        let description = self.descriptionTextView.text
        self.videoSettings = VideoSettings(title: title, description: description, privacy: "nobody", users: nil, password: nil)
     
        let operation = self.operation as! ExportQuotaCreateOperation
        
        if operation.state == .executing
        {
            operation.videoSettings = self.videoSettings

            self.activityIndicatorView.startAnimating() // Listen for operation completion, dismiss
        }
        else if let error = operation.error
        {
            self.presentOperationErrorAlert(with: error)
        }
        else
        {
            if let video = self.uploadTicket?.video, let viewPrivacy = video.privacy?.view, viewPrivacy != VideoSettingsViewController.PreUploadViewPrivacy
            {
                NotificationCenter.default.post(name: Notification.Name(rawValue: type(of: self).UploadInitiatedNotification), object: video)
                
                self.dismiss(animated: true, completion: nil)
            }
            else
            {
                self.activityIndicatorView.startAnimating()
                self.applyVideoSettings()
            }
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        self.descriptionTextView.becomeFirstResponder()
        
        return false
    }
    
    // MARK: UI Presentation
    
    private func presentOperationErrorAlert(with error: NSError)
    {
        // TODO: check error.code == AVError.DiskFull.rawValue and message appropriately
        // TODO: check error.code == AVError.OperationInterrupted.rawValue (app backgrounded during export)
        
        let alert = UIAlertController(title: "Operation Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            _ = self?.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            self?.activityIndicatorView.startAnimating()
            self?.setupAndStartOperation()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentVideoSettingsErrorAlert(with error: NSError)
    {
        let alert = UIAlertController(title: "Video Settings Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            _ = self?.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            self?.activityIndicatorView.startAnimating()
            self?.applyVideoSettings()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Private API
    
    private func applyVideoSettings()
    {
        guard let videoUri = self.uploadTicket?.video?.uri, let videoSettings = self.videoSettings else
        {
            return
        }
        
        do
        {
            self.task = try NewVimeoUploader.sharedInstance.foregroundSessionManager.videoSettingsDataTask(videoUri: videoUri, videoSettings: videoSettings, completionHandler: { [weak self] (video, error) -> Void in
                
                self?.task = nil
                
                DispatchQueue.main.async(execute: { [weak self] () -> Void in
                    guard let strongSelf = self else
                    {
                        return
                    }
                    
                    strongSelf.activityIndicatorView.stopAnimating()
                    
                    if let error = error
                    {
                        strongSelf.presentVideoSettingsErrorAlert(with: error)
                    }
                    else
                    {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: VideoSettingsViewController.UploadInitiatedNotification), object: video)
                        
                        strongSelf.dismiss(animated: true, completion: nil)
                    }
                })
            })
            
            self.task?.resume()
        }
        catch let error as NSError
        {
            self.activityIndicatorView.stopAnimating()
            self.presentVideoSettingsErrorAlert(with: error)
        }
    }
}

//
//  VideoSettingsViewController.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 10/16/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit
import Photos

class VideoSettingsViewController: UIViewController
{
    private static let ProgressKeyPath = "uploadProgress"
    private var uploadProgressKVOContext = UInt8()

    private var phAssetOperation: PHAssetOperation?
    private var exportVideoOperation: ExportVideoOperation?
    private var uploadDescriptor: UploadDescriptor?
    
    var phAsset: PHAsset?

    deinit
    {
        self.removeObservers()
        self.exportVideoOperation?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.phAsset != nil, "self.phAsset cannot be nil")
        
        self.title = "Video Settings"

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "didTapCancel:")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "didTapDone:")
        
        self.fetchAVAsset(self.phAsset!)
    }
    
    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
        self.phAssetOperation?.cancel()
        self.exportVideoOperation?.cancel()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func didTapDone(sender: UIBarButtonItem)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Private API
    
    private func fetchAVAsset(phAsset: PHAsset)
    {
        self.phAssetOperation = PHAssetOperation(phAsset: phAsset)
        self.phAssetOperation?.progressBlock = { (progress: Double) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("PHAsset download progress: \(progress)")
            })
        }
        
        self.phAssetOperation?.completionBlock = { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let error = strongSelf.phAssetOperation?.error
                {
                    print("Error retrieving PHAsset's AVAsset: \(error.localizedDescription)")
                }
                else if let avAsset = strongSelf.phAssetOperation?.avAsset
                {
                    strongSelf.exportAVAsset(avAsset)
                }
                
                strongSelf.phAssetOperation = nil
            })
        }
        
        self.phAssetOperation?.start()
    }
    
    private func exportAVAsset(avAsset: AVAsset)
    {
        self.exportVideoOperation = ExportVideoOperation(asset: avAsset)
        self.exportVideoOperation?.progressBlock = { (progress: Double) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                print("Export progress: \(progress)")
            })
        }
        
        self.exportVideoOperation?.completionBlock = { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let error = strongSelf.exportVideoOperation?.error
                {
                    print("Error exporting AVAsset: \(error.localizedDescription)")
                }
                else if let outputURL = strongSelf.exportVideoOperation?.outputURL
                {
                    strongSelf.uploadFile(outputURL)
                }
                
                strongSelf.exportVideoOperation = nil
            })
        }
        
        self.exportVideoOperation?.start()
    }
    
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

//
//  CameraRollViewController.swift
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
import Photos

class CameraRollViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    
    private var phAssets: [PHAsset] = []
    
    private static let ProgressKeyPath = "uploadProgress"
    private var uploadProgressKVOContext = UInt8()
    
    private var phAssetOperation: PHAssetOperation?
    private var exportVideoOperation: ExportVideoOperation?
    private var uploadDescriptor: UploadDescriptor?

    // MARK: Lifecycle
    
    deinit
    {
        self.removeObservers()
        self.exportVideoOperation?.cancel()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.title = "Camera Roll"
        
        self.phAssets = self.loadAssets()

        self.setupTableView()
    }
    
    // MARK: Setup
    
    private func setupTableView()
    {
        let nib = UINib(nibName: "PHAssetCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: PHAssetCell.CellIdentifier)
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let phAsset = self.phAssets[indexPath.row]
        
        self.fetchAVAsset(phAsset)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.phAssets.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(PHAssetCell.CellIdentifier) as! PHAssetCell
        
        cell.phAsset = self.phAssets[indexPath.row]
        
        return cell
    }
    
    // MARK: Utilities

    private func loadAssets() -> [PHAsset]
    {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
        
        var phAssets: [PHAsset] = []
        result.enumerateObjectsUsingBlock( { (phAsset, index, stop) -> Void in
            phAssets.append(phAsset as! PHAsset)
        })
        
        return phAssets
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
                    strongSelf.startUpload(outputURL)
                }
                
                strongSelf.exportVideoOperation = nil
            })
        }
        
        self.exportVideoOperation?.start()
    }
    
    private func startUpload(url: NSURL)
    {
        self.removeObservers()
        
        let videoSettings = VideoSettings(title: "hey!!", description: nil, privacy: "goo", users: nil)
        self.uploadDescriptor = UploadDescriptor(url: url, videoSettings: videoSettings)
        self.uploadDescriptor!.identifier = "\(url.absoluteString.hash)"
        
        self.addObservers()
        
        try! UploadManager.sharedInstance.descriptorManager.addDescriptor(self.uploadDescriptor!)
    }
    
    // MARK: KVO
    
    private func addObservers()
    {
        self.uploadDescriptor?.addObserver(self, forKeyPath: CameraRollViewController.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.uploadProgressKVOContext)
    }
    
    private func removeObservers()
    {
        self.uploadDescriptor?.removeObserver(self, forKeyPath: CameraRollViewController.ProgressKeyPath, context: &self.uploadProgressKVOContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(CameraRollViewController.ProgressKeyPath, &self.uploadProgressKVOContext):
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    print("VC upload progress: \(progress)")
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

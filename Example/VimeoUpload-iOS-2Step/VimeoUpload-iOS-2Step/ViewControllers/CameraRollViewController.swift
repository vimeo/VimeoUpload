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
import AVFoundation

class CameraRollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    static let NibName = "CameraRollViewController"
    private static let CollectionViewSpacing: CGFloat = 2
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var assets: [PHAssetContainer] = []
    private var phAssetHelper = PHAssetHelper(imageManager: PHImageManager.defaultManager())
    private var uploadPrepOperation: UploadPrepOperation?
    
    private var selectedIndexPath: NSIndexPath?
    
    // MARK: Lifecycle
    
    deinit
    {
        self.uploadPrepOperation?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.assets = self.loadAssets()

        self.setupNavigationBar()
        self.setupCollectionView()
        self.setupUploadPrepOperation()
    }
    
    // MARK: Setup

    private func loadAssets() -> [PHAssetContainer]
    {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
        
        var assets: [PHAssetContainer] = []
        result.enumerateObjectsUsingBlock( { (phAsset, index, stop) -> Void in
            
            let phAsset = phAsset as! PHAsset
            let phAssetContainer = PHAssetContainer(phAsset: phAsset)
            assets.append(phAssetContainer)
        
        })
        
        return assets
    }

    private func setupNavigationBar()
    {
        self.title = "Camera Roll"
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "didTapCancel:")
        self.navigationItem.leftBarButtonItem = cancelItem
    }

    private func setupCollectionView()
    {
        let nib = UINib(nibName: CameraRollCell.NibName, bundle: nil)
        self.collectionView.registerNib(nib, forCellWithReuseIdentifier: CameraRollCell.CellIdentifier)
        
        let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.minimumInteritemSpacing = CameraRollViewController.CollectionViewSpacing
        layout?.minimumLineSpacing = CameraRollViewController.CollectionViewSpacing
    }
    
    private func setupUploadPrepOperation()
    {
        let sessionManager = UploadManager.sharedInstance.sessionManager
        let operation = UploadPrepOperation(sessionManager: sessionManager)
        self.setUploadPrepOperationBlocks(operation)
        self.uploadPrepOperation = operation
        self.uploadPrepOperation?.start()
    }
    
    // TODO: teardown this upload prep block when view is cancelled or when asset is selected?
    // TODO: Should some or all of these blocks be delegate calls instead?
    
    private func setUploadPrepOperationBlocks(operation: UploadPrepOperation)
    {
        operation.downloadProgressBlock = { (progress: Double) -> Void in
            print("Download progress: \(progress)")
        }
        operation.exportProgressBlock = { (progress: Double) -> Void in
            print("Export progress: \(progress)")
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
                    print("Upload prep error: \(error)")

                    if let indexPath = strongSelf.selectedIndexPath
                    {
                        strongSelf.presentUploadPrepErrorAlert(indexPath, error: error)
                    }
                    // else: do nothing, the error will be communicated at the time of cell selection
                }
                else
                {
                    print("Upload prep complete! \(operation.result!)")
                    strongSelf.presentVideoSettings()
                }
            })
        }
    }
     
    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
        self.uploadPrepOperation?.cancel()
        
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.assets.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CameraRollCell.CellIdentifier, forIndexPath: indexPath) as! CameraRollCell
        
        let phAssetContainer = self.assets[indexPath.item]
        
        cell.setDuration(phAssetContainer.phAsset.duration)

        self.requestImageForCell(cell, phAssetContainer: phAssetContainer)
        self.requestAssetForCell(cell, phAssetContainer: phAssetContainer)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    {
        let phAssetContainer = self.assets[indexPath.item]
        let phAsset = phAssetContainer.phAsset
        
        self.phAssetHelper.cancelRequestsForPHAsset(phAsset)
    }
    
    // MARK: UICollectionViewFlowLayoutDelegate
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let dimension = (collectionView.bounds.size.width - CameraRollViewController.CollectionViewSpacing) / 2

        return CGSizeMake(dimension, dimension)
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        self.didSelectIndexPath(indexPath)
    }
    
    // MARK: Private API
    
    private func requestImageForCell(cell: CameraRollCell, phAssetContainer: PHAssetContainer)
    {
        let phAsset = phAssetContainer.phAsset
        let size = cell.bounds.size
        let scale = UIScreen.mainScreen().scale
        let scaledSize = CGSizeMake(scale * size.width, scale * size.height)

        self.phAssetHelper.requestImage(phAsset, size: scaledSize) { [weak self] (image, inCloud, error) -> Void in
            
            guard let _ = self else
            {
                return
            }
            
            if let inCloud = inCloud
            {
                phAssetContainer.inCloud = inCloud
                
                if inCloud == true
                {
                    cell.setError("iCloud Asset")
                }
            }

            if let image = image
            {
                cell.setImage(image)
            }
            else if let error = error
            {
                cell.setError(error.localizedDescription)
            }
        }
    }
    
    private func requestAssetForCell(cell: CameraRollCell, phAssetContainer: PHAssetContainer)
    {
        let phAsset = phAssetContainer.phAsset
        
        self.phAssetHelper.requestAsset(phAsset, completion: { [weak self] (asset, inCloud, error) -> Void in
            
            guard let _ = self else
            {
                return
            }
            
            // Cache the asset and inCloud values for later use in didSelectItem
            
            if let inCloud = inCloud
            {
                phAssetContainer.inCloud = inCloud
                
                if inCloud == true
                {
                    cell.setError("iCloud Asset")
                }
            }
            
            if let asset = asset
            {
                phAssetContainer.avAsset = asset
                
                let megabytes = asset.approximateFileSizeInMegabytes()
                cell.setFileSize(megabytes)
            }
            else if let error = error
            {
                cell.setError(error.localizedDescription)
            }
        })
    }
    
    private func didSelectIndexPath(indexPath: NSIndexPath)
    {
        let phAssetContainer = self.assets[indexPath.item]
        
        // Check if an error occurred when attempting to retrieve the asset
        if phAssetContainer.inCloud == nil && phAssetContainer.avAsset == nil
        {
            self.presentAssetErrorAlert(indexPath)
            
            return
        }
        
        // Check if we were told the asset is on device but were not provided an asset (this should never happen)
        if let inCloud = phAssetContainer.inCloud where inCloud == false && phAssetContainer.avAsset == nil
        {
            self.presentAssetErrorAlert(indexPath)
        
            return
        }
        
        self.selectedIndexPath = indexPath

        if let error = self.uploadPrepOperation?.error
        {
            self.presentUploadPrepErrorAlert(indexPath, error: error)
        }
        else
        {
            self.uploadPrepOperation?.selectPHAssetContainer(phAssetContainer)
        }
    }
    
    // MARK: UI Presentation

    private func presentAssetErrorAlert(indexPath: NSIndexPath)
    {
        self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)

        let alert = UIAlertController(title: "Asset Error", message: "An error occurred when requesting the avAsset.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.collectionView.reloadItemsAtIndexPaths([indexPath]) // Let the user manually reselect the cell since reload is async
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentUploadPrepErrorAlert(indexPath: NSIndexPath, error: NSError)
    {
        let alert = UIAlertController(title: "Upload Prep Error", message: "An error occurred when preparing this upload.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            
            self?.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            
        }))

        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
        
            guard let strongSelf = self else
            {
                return
            }
            
            let operation = strongSelf.uploadPrepOperation!.retryableOperation()
            strongSelf.setUploadPrepOperationBlocks(operation)
            strongSelf.uploadPrepOperation = operation
            operation.start()
            
            let phAssetContainer = strongSelf.assets[indexPath.item]
            operation.selectPHAssetContainer(phAssetContainer)
        
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentVideoSettings()
    {
        let viewController = VideoSettingsViewController(nibName: VideoSettingsViewController.NibName, bundle:NSBundle.mainBundle())
        viewController.uploadPrepOperation = self.uploadPrepOperation
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

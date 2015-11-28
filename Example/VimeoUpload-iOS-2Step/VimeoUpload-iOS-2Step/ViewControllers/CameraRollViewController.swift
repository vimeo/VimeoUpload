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

typealias CameraRollViewControllerResult = (me: VIMUser, phAssetContainer: PHAssetContainer)

class CameraRollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    static let NibName = "CameraRollViewController"
    private static let CollectionViewSpacing: CGFloat = 2
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var assets: [PHAssetContainer] = []
    private var phAssetHelper = PHAssetHelper(imageManager: PHImageManager.defaultManager())
    private var operation: CompositeQuotaOperation?
    
    private var selectedIndexPath: NSIndexPath?
    
    // MARK: Lifecycle
    
    deinit
    {
        self.operation?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.assets = self.loadAssets()

        self.setupNavigationBar()
        self.setupCollectionView()
        
        self.setupOperation(nil)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if let indexPath = self.selectedIndexPath // Deselect the previously selected item upon return from video settings
        {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }
    }
    
    // MARK: Setup

    private func setupNavigationBar()
    {
        self.title = "Camera Roll"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "didTapCancel:")
    }
        
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

    private func setupCollectionView()
    {
        let nib = UINib(nibName: CameraRollCell.NibName, bundle: nil)
        self.collectionView.registerNib(nib, forCellWithReuseIdentifier: CameraRollCell.CellIdentifier)
        
        let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.minimumInteritemSpacing = CameraRollViewController.CollectionViewSpacing
        layout?.minimumLineSpacing = CameraRollViewController.CollectionViewSpacing
    }
    
    private func setupOperation(me: VIMUser?)
    {
        let sessionManager = ForegroundSessionManager.sharedInstance
        let operation = CompositeQuotaOperation(sessionManager: sessionManager, me: me)
        self.setOperationBlocks(operation)
        self.operation = operation
        self.operation?.start()
    }
        
    private func setOperationBlocks(operation: CompositeQuotaOperation)
    {
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
                
                strongSelf.activityIndicatorView.stopAnimating()

                if let error = operation.error
                {
                    if let indexPath = strongSelf.selectedIndexPath
                    {
                        strongSelf.presentErrorAlert(indexPath, error: error)
                    }
                    // else: do nothing, the error will be communicated at the time of cell selection
                }
                else
                {
                    let indexPath = strongSelf.selectedIndexPath!
                    let phAssetContainer = strongSelf.assets[indexPath.item]

                    strongSelf.finish(phAssetContainer)
                }
            })
        }
    }
     
    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
        self.operation?.cancel()
        
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
        
        self.phAssetHelper.requestImage(phAsset: phAsset, size: scaledSize) { [weak self, weak cell] (image, inCloud, error) -> Void in
            
            guard let _ = self, let strongCell = cell else
            {
                return
            }
            
            // Cache the inCloud value for later use in didSelectItem
            phAssetContainer.inCloud = inCloud
            phAssetContainer.error = error

            if let inCloud = inCloud where inCloud == true
            {
                strongCell.setError("iCloud Asset")
            }

            if let image = image
            {
                strongCell.setImage(image)
            }
            else if let error = error
            {
                strongCell.setError(error.localizedDescription)
            }
        }
    }
    
    private func requestAssetForCell(cell: CameraRollCell, phAssetContainer: PHAssetContainer)
    {
        let phAsset = phAssetContainer.phAsset
        
        self.phAssetHelper.requestAsset(phAsset: phAsset, completion: { [weak self, weak cell] (asset, inCloud, error) -> Void in
            
            guard let _ = self, let strongCell = cell else
            {
                return
            }
            
            // Cache the asset and inCloud values for later use in didSelectItem
            phAssetContainer.avAsset = asset
            phAssetContainer.inCloud = inCloud
            phAssetContainer.error = error

            if let inCloud = inCloud where inCloud == true
            {
                strongCell.setError("iCloud Asset")
            }
            
            if let asset = asset
            {
                let megabytes = asset.approximateFileSizeInMegabytes()
                strongCell.setFileSize(megabytes)
            }
            else if let error = error
            {
                strongCell.setError(error.localizedDescription)
            }
        })
    }
    
    private func didSelectIndexPath(indexPath: NSIndexPath)
    {
        let phAssetContainer = self.assets[indexPath.item]
        
        // Check if an error occurred when attempting to retrieve the asset
        if let error = phAssetContainer.error
        {
            self.presentAssetErrorAlert(indexPath, error: error)
            
            return
        }
        
        self.selectedIndexPath = indexPath

        if let error = self.operation?.error
        {
            self.presentErrorAlert(indexPath, error: error)
        }
        else
        {
            if AFNetworkReachabilityManager.sharedManager().reachable == false
            {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "The internet connection appears to be offline."])
                self.presentErrorAlert(indexPath, error: error)
                
                return
            }

            // Only show the activity indicator UI if the network request is in progress
            if self.operation?.me == nil
            {
                self.activityIndicatorView.startAnimating()
            }
            
            self.operation?.fulfillSelection(avAsset: phAssetContainer.avAsset) // avAsset may or may not be nil, which is fine
        }
    }
    
    // MARK: UI Presentation

    private func presentAssetErrorAlert(indexPath: NSIndexPath, error: NSError)
    {
        let alert = UIAlertController(title: "Asset Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.collectionView.reloadItemsAtIndexPaths([indexPath]) // Let the user manually reselect the cell since reload is async
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentErrorAlert(indexPath: NSIndexPath, error: NSError)
    {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.selectedIndexPath = nil
            strongSelf.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            strongSelf.setupOperation(strongSelf.operation?.me)
        }))

        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
        
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.setupOperation(strongSelf.operation?.me)
            strongSelf.didSelectIndexPath(indexPath)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func finish(phAssetContainer: PHAssetContainer)
    {
        let me = self.operation!.me!

        self.setupOperation(me) // Reset the operation
        
        let viewController = VideoSettingsViewController(nibName: VideoSettingsViewController.NibName, bundle:NSBundle.mainBundle())
        viewController.input = CameraRollViewControllerResult(me: me, phAssetContainer: phAssetContainer)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

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

typealias CameraRollSelection = (avAsset: AVAsset, indexPath: NSIndexPath)

class CameraRollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    static let NibName = "CameraRollViewController"
    private static let CollectionViewSpacing: CGFloat = 2
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var assets: [VimeoPHAsset] = []
    private var phAssetHelper = PHAssetHelper(imageManager: PHImageManager.defaultManager())
    private var meTask: NSURLSessionDataTask?
    private var selection: CameraRollSelection?
    
    // MARK: Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.assets = self.loadAssets()

        self.setupNavigationBar()
        self.setupCollectionView()
        self.refreshUser() // Refresh the user object to ensure we have up to date upload quota information
    }
    
    // MARK: Setup

    private func loadAssets() -> [VimeoPHAsset]
    {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let result = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
        
        var assets: [VimeoPHAsset] = []
        result.enumerateObjectsUsingBlock( { (phAsset, index, stop) -> Void in
            
            let phAsset = phAsset as! PHAsset
            let vimeoPHAsset = VimeoPHAsset(phAsset: phAsset)
            assets.append(vimeoPHAsset)
        
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
    
    private func refreshUser()
    {
        // TODO: refresh the user object here
        
        self.meTask = try? UploadManager.sharedInstance.sessionManager.meDataTask()
        self.meTask?.resume()
        
//        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
//        dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] () -> Void in
//            
//            guard let strongSelf = self else
//            {
//                return
//            }
//            
//            strongSelf.meTask = nil
//        
//            // TODO: check for error, alert if error not nil
//            
//            if let selection = strongSelf.selection
//            {
//                strongSelf.selection = nil
//
//                // TODO: hide activity indicator
//                
//                strongSelf.performPreliminaryValidation(selection.avAsset, indexPath: selection.indexPath)
//            }
//        }
    }
    
    // MARK: Actions
    
    func didTapCancel(sender: UIBarButtonItem)
    {
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
        
        let vimeoPHAsset = self.assets[indexPath.item]
        
        cell.setDuration(vimeoPHAsset.phAsset.duration)

        self.requestImageForCell(cell, vimeoPHAsset: vimeoPHAsset)
        self.requestAssetForCell(cell, vimeoPHAsset: vimeoPHAsset)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    {
        let vimeoPHAsset = self.assets[indexPath.item]
        let phAsset = vimeoPHAsset.phAsset
        
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
    
    private func requestImageForCell(cell: CameraRollCell, vimeoPHAsset: VimeoPHAsset)
    {
        let phAsset = vimeoPHAsset.phAsset
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
                vimeoPHAsset.inCloud = inCloud
                
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
    
    private func requestAssetForCell(cell: CameraRollCell, vimeoPHAsset: VimeoPHAsset)
    {
        let phAsset = vimeoPHAsset.phAsset
        
        self.phAssetHelper.requestAsset(phAsset, networkAccessAllowed: false, progress: nil, completion: { [weak self] (asset, inCloud, error) -> Void in
            
            guard let _ = self else
            {
                return
            }
            
            // Cache the asset and inCloud values for later use in didSelectItem
            
            if let inCloud = inCloud
            {
                vimeoPHAsset.inCloud = inCloud
                
                if inCloud == true
                {
                    cell.setError("iCloud Asset")
                }
            }
            
            if let asset = asset
            {
                vimeoPHAsset.avAsset = asset
                
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
        self.selection = nil // Reset the current selection, if any
        
        let vimeoPHAsset = self.assets[indexPath.item]
        
        // Check if an error occurred when attempting to retrieve the asset
        if (vimeoPHAsset.inCloud == nil && vimeoPHAsset.avAsset == nil)
        {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.presentAssetErrorAlert(indexPath)
            
            return
        }
        
        // Check if we were told the asset is on device but were not provided an asset
        if let inCloud = vimeoPHAsset.inCloud where inCloud == false && vimeoPHAsset.avAsset == nil
        {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.presentAssetErrorAlert(indexPath)
        
            return
        }
        
        if let inCloud = vimeoPHAsset.inCloud where inCloud == true
        {
            let phAsset = vimeoPHAsset.phAsset
            self.downloadAsset(phAsset, indexPath: indexPath)
            
            return
        }
        
        if let asset = vimeoPHAsset.avAsset
        {
            self.performPreliminaryValidation(asset, indexPath: indexPath)
            
            return
        }
        
        assertionFailure("Execution should never reach this point")
    }
    
    private func downloadAsset(phAsset: PHAsset, indexPath: NSIndexPath)
    {
        // TODO: show progress indicator 
        
        self.phAssetHelper.requestAsset(phAsset, networkAccessAllowed: true, progress: { [weak self] (progress, error, stop, info) -> Void in

            guard let _ = self else
            {
                return
            }
            
            print(progress)

        }, completion: { [weak self] (asset, inCloud, error) -> Void in

            guard let strongSelf = self else
            {
                return
            }
            
            // TODO: hide progress indicator
            
            if let _ = error // TODO: log this error in Localytics
            {
                strongSelf.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
                strongSelf.presentDownloadErrorAlert(phAsset, indexPath: indexPath)
            }
            else if let asset = asset
            {
                strongSelf.performPreliminaryValidation(asset, indexPath: indexPath)
            }
            else
            {
                assertionFailure("Execution should never reach this point")
            }

        })
    }
    
    private func performPreliminaryValidation(avAsset: AVAsset, indexPath: NSIndexPath)
    {
        // If the user refresh task has not yet completed then we can't perform the quota check, abort and wait for it to complete
        if self.meTask != nil
        {
            // Hold a reference to the selected indexPath, to be used when the refresh user task completes
            self.selection = CameraRollSelection(avAsset: avAsset, indexPath: indexPath)

            // TODO: show activity indicator
            
            return
        }
        
        let uploadQuotaAvailable = self.checkUploadQuotaAvailable(avAsset)
        guard uploadQuotaAvailable == true else
        {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.presentQuotaAlert()
            
            return
        }
        
        let diskSpaceAvailable = self.checkDiskSpaceAvailable(avAsset)
        guard diskSpaceAvailable == true else
        {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.presentDiskSpaceAlert()
            
            return
        }
        
        self.presentVideoSettings(avAsset)
    }
    
    // Because we haven't yet exported the asset we check against approximate filesize
    private func checkDiskSpaceAvailable(avAsset: AVAsset) -> Bool
    {
        let fileSize = avAsset.approximateFileSize()
        do
        {
            if let availableDiskSpace = try NSFileManager.defaultManager().availableDiskSpace()
            {
                return availableDiskSpace.doubleValue > fileSize
            }

            return true // If we can't calculate the available disk space we proceed beacuse we'll catch any real error later during export
        }
        catch
        {
            return true
        }
    }

    // Because we haven't yet exported the asset we check against approximate filesize
    private func checkUploadQuotaAvailable(avAsset: AVAsset) -> Bool
    {
        // TODO: implement this method
        return true
    }
    
    // MARK: UI Presentation

    private func presentAssetErrorAlert(indexPath: NSIndexPath)
    {
        let alert = UIAlertController(title: "Asset Error", message: "An error occurred when requesting the avAsset.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.collectionView.reloadItemsAtIndexPaths([indexPath])
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentDownloadErrorAlert(phAsset: PHAsset, indexPath: NSIndexPath)
    {
        let alert = UIAlertController(title: "Download Error", message: "An error occurred when downloading the avAsset.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.downloadAsset(phAsset, indexPath: indexPath)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentQuotaAlert()
    {
        let alert = UIAlertController(title: "Upload Quota", message: "Upgrade your account and try again.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentDiskSpaceAlert()
    {
        let alert = UIAlertController(title: "Disk Space", message: "Clear some space on your device and try again.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func presentVideoSettings(avAsset: AVAsset)
    {
        let viewController = VideoSettingsViewController(nibName: VideoSettingsViewController.NibName, bundle:NSBundle.mainBundle())
        viewController.avAsset = avAsset
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

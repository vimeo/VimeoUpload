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

class CameraRollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    static let NibName = "CameraRollViewController"
    private static let CollectionViewSpacing: CGFloat = 2
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var assets: [VimeoPHAsset] = []
    private var phAssetHelper = PHAssetHelper(imageManager: PHImageManager.defaultManager())
    private var userRefreshTask: NSURLSessionDataTask?
    private var selectedIndexPath: NSIndexPath?
    
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
        
        self.userRefreshTask = NSURLSessionDataTask()

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.userRefreshTask = nil
        
            // TODO: check for error, alert if error not nil
            
            if let selectedIndexPath = strongSelf.selectedIndexPath
            {
                strongSelf.selectedIndexPath = nil

                let cell = strongSelf.collectionView.cellForItemAtIndexPath(selectedIndexPath) as! CameraRollCell
                cell.showActivity(false)

                let vimeoPHAsset = strongSelf.assets[selectedIndexPath.item]
                strongSelf.didSelectAsset(vimeoPHAsset)
            }
        }
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
        
        self.phAssetHelper.requestImage(vimeoPHAsset, cell: cell, indexPath: indexPath)
        
        // If we have a cached asset, use it, otherwise request it
        
        if let asset = vimeoPHAsset.avAsset
        {
            self.phAssetHelper.configureCellForAsset(cell, asset: asset)
        }
        else
        {
            self.phAssetHelper.requestAsset(vimeoPHAsset, cell: cell, indexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    {
        self.phAssetHelper.cancelRequestsForCellAtIndexPath(indexPath)
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
        self.selectedIndexPath = nil // Reset any currently selected asset
        
        let vimeoPHAsset = self.assets[indexPath.item]
        
        if self.validateAsset(vimeoPHAsset) == false
        {
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            
            // Give the user the option to re-request the asset (trigger re-request by simply reloading the appropriate cell)
            
            let alert = UIAlertController(title: "Nil Asset", message: "An error occurred earlier when requesting the avAsset.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
               
                collectionView.reloadItemsAtIndexPaths([indexPath])
                
            }))
            self.presentViewController(alert, animated: true, completion: nil)

            return
        }

        // We have already refreshed the user object, okay to proceed with disk space and quota checks          
        if self.userRefreshTask == nil
        {
            self.didSelectAsset(vimeoPHAsset)
            
            return
        }
    

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CameraRollCell
        cell.showActivity(true)
        
        self.selectedIndexPath = indexPath // Hold a reference to the selected indexPath, to be used when the refresh user task completes
    }
    
    // MARK: Private API
    
    // Ensure that either the asset is in iCloud or we have a non-nil avAsset

    private func validateAsset(vimeoPHAsset: VimeoPHAsset) -> Bool
    {
        guard let inCloud = vimeoPHAsset.inCloud else
        {
            return false
        }
        
        if inCloud == true
        {
            return true
        }
        
        guard vimeoPHAsset.avAsset != nil else
        {
            return false
        }

        return true
    }
    
    private func didSelectAsset(vimeoPHAsset: VimeoPHAsset)
    {
        // 1. Check if the asset is in iCloud, if so let video setting view controller handle download
        
        if vimeoPHAsset.inCloud! == true
        {
            self.presentVideoSettings(vimeoPHAsset)
            
            return
        }
        
        // TODO: deselect cells when alert is presented
        
        // 2. Check upload quota
        
        let uploadQuotaAvailable = self.checkUploadQuotaAvailable(vimeoPHAsset.avAsset!)
        guard uploadQuotaAvailable == true else
        {
            let alert = UIAlertController(title: "Upload Quota", message: "Upgrade your account and try again.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        // 3. Check disk space
        
        let diskSpaceAvailable = try? self.checkDiskSpaceAvailable(vimeoPHAsset.avAsset!) ?? true
        guard diskSpaceAvailable == true else
        {
            let alert = UIAlertController(title: "Disk Space", message: "Clear some space on your device and try again.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }

        // 4. Present video settings view controller
        
        self.presentVideoSettings(vimeoPHAsset)
    }
    
    // TODO: move these two methods into reusable component
    // TODO: fill in this error info
    
    // Because we haven't yet exported the asset we check against approximate filesize
    
    private func checkDiskSpaceAvailable(avAsset: AVAsset) throws -> Bool
    {
        let fileSize = avAsset.approximateFileSize()
        guard let availableDiskSpace = try NSFileManager.defaultManager().availableDiskSpace() else
        {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to calculate available disk space"])
        }
        
        return availableDiskSpace.doubleValue > fileSize
    }

    // TODO: implement this method

    // Because we haven't yet exported the asset we check against approximate filesize

    private func checkUploadQuotaAvailable(avAsset: AVAsset) -> Bool
    {
        return true
    }

    private func presentVideoSettings(vimeoPHAsset: VimeoPHAsset)
    {
        let viewController = VideoSettingsViewController(nibName: VideoSettingsViewController.NibName, bundle:NSBundle.mainBundle())
        viewController.vimeoPHAsset = vimeoPHAsset
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

//
//  BaseCameraRollViewController.swift
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
import AVFoundation
import Photos
import VIMNetworking
import AFNetworking

typealias UploadUserAndCameraRollAsset = (user: VIMUser, cameraRollAsset: CameraRollAsset)

/*
    This viewController displays the device camera roll video contents. 

    It starts an operation on load that requests a fresh version of the authenticated user, checks that user's daily quota, and if the user selects a non-iCloud asset it checks the weekly quota and available diskspace. 

    Essentially, it performs all checks possible at this UX juncture to determine if we can proceed with the upload.

    [AH] 12/03/2015
*/

class BaseCameraRollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    static let NibName = "BaseCameraRollViewController"
    private static let CollectionViewSpacing: CGFloat = 2
    
    var sessionManager: VimeoSessionManager!
    
    // MARK: 
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK: 
    
    private var assets: [CameraRollAsset] = []
    private var cameraRollAssetHelper: CameraRollAssetHelper?
    private var operation: MeQuotaOperation?
    private var me: VIMUser? // We store this in a property instead of on the operation itself, so that we can refresh it independent of the operation [AH]
    private var meOperation: MeOperation?
    private var selectedIndexPath: NSIndexPath?
    
    // MARK: Lifecycle
    
    deinit
    {
        self.removeObservers()
        self.meOperation?.cancel()
        self.operation?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.cameraRollAssetHelper = PHAssetHelper()
        self.assets = self.loadAssets()

        self.addObservers()
        self.setupNavigationBar()
        self.setupCollectionView()
        self.setupAndStartOperation()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if let indexPath = self.selectedIndexPath // Deselect the previously selected item upon return from video settings
        {
            self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }
    }
    
    // MARK: Observers
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    // Ensure that we refresh the me object on return from background
    // In the event that a user modified their upload quota while the app was backgrounded [AH] 12/06/2015
    
    func applicationWillEnterForeground(notification: NSNotification)
    {
        if self.meOperation != nil
        {
            return
        }
        
        let operation = MeOperation(sessionManager: self.sessionManager)
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                strongSelf.meOperation = nil
                
                if operation.cancelled == true
                {
                    return
                }
                
                if operation.error != nil
                {
                    return
                }

                strongSelf.me = operation.result!
            })
        }

        self.meOperation = operation
        operation.start()
    }

    // MARK: Setup
    
    private func loadAssets() -> [CameraRollAsset]
    {
        var assets = [CameraRollAsset]()

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssetsWithMediaType(.Video, options: options)

        fetchResult.enumerateObjectsUsingBlock{ (object: AnyObject?, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in

            if let phAsset = object as? PHAsset
            {
                let vimPHAsset = VIMPHAsset(phAsset: phAsset)
                assets.append(vimPHAsset)
            }
        }        
        
        return assets
    }

    private func setupCollectionView()
    {
        let nib = UINib(nibName: DemoCameraRollCell.NibName, bundle: nil)
        self.collectionView.registerNib(nib, forCellWithReuseIdentifier: DemoCameraRollCell.CellIdentifier)
        
        let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.minimumInteritemSpacing = BaseCameraRollViewController.CollectionViewSpacing
        layout?.minimumLineSpacing = BaseCameraRollViewController.CollectionViewSpacing
    }
    
    private func setupAndStartOperation()
    {
        let operation = MeQuotaOperation(sessionManager: self.sessionManager, me: self.me)
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
                    let cameraRollAsset = strongSelf.assets[indexPath.item]
                    strongSelf.me = operation.me!
   
                    strongSelf.finish(cameraRollAsset: cameraRollAsset)
                }
            })
        }

        self.operation = operation
        self.operation?.start()
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.assets.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(DemoCameraRollCell.CellIdentifier, forIndexPath: indexPath) as! DemoCameraRollCell
        
        let cameraRollAsset = self.assets[indexPath.item]
        
        self.cameraRollAssetHelper?.requestImage(cell: cell, cameraRollAsset: cameraRollAsset)
        self.cameraRollAssetHelper?.requestAsset(cell: cell, cameraRollAsset: cameraRollAsset)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
    {
        let cameraRollAsset = self.assets[indexPath.item] 
        
        self.cameraRollAssetHelper?.cancelRequests?(cameraRollAsset)
    }
    
    // MARK: UICollectionViewFlowLayoutDelegate
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let dimension = (collectionView.bounds.size.width - BaseCameraRollViewController.CollectionViewSpacing) / 2

        return CGSizeMake(dimension, dimension)
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        self.didSelectIndexPath(indexPath)
    }
    
    // MARK: Private API
        
    private func didSelectIndexPath(indexPath: NSIndexPath)
    {
        let cameraRollAsset = self.assets[indexPath.item]
        
        // Check if an error occurred when attempting to retrieve the asset
        if let error = cameraRollAsset.error
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
            
            // The avAsset may or may not be nil, which is fine. Becuase at the very least this operation needs to fetch "me"
            self.operation?.fulfillSelection(avAsset: cameraRollAsset.avAsset)
        }
    }
    
    // MARK: UI Presentation

    private func presentAssetErrorAlert(indexPath: NSIndexPath, error: NSError)
    {
        let alert = UIAlertController(title: "Asset Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
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
            strongSelf.setupAndStartOperation()
        }))

        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
        
            guard let strongSelf = self else
            {
                return
            }

            strongSelf.setupAndStartOperation()
            strongSelf.didSelectIndexPath(indexPath)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    private func finish(cameraRollAsset cameraRollAsset: CameraRollAsset)
    {
        let me = self.me!

        // Reset the operation so we're prepared to retry upon cancellation from video settings [AH] 12/06/2015
        self.setupAndStartOperation()
        
        let result = UploadUserAndCameraRollAsset(user: me, cameraRollAsset: cameraRollAsset)
        self.didFinishWithResult(result)        
    }
    
    // MARK: Overrides
    
    func setupNavigationBar()
    {
        self.title = "Camera Roll"
    }

    func didFinishWithResult(result: UploadUserAndCameraRollAsset)
    {
        assertionFailure("Subclasses must override")
    }
}

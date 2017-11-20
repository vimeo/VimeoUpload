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
import VimeoNetworking
import AFNetworking
import VimeoUpload

class BaseCameraRollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    static let NibName = "BaseCameraRollViewController"
    private static let CollectionViewSpacing: CGFloat = 2
    
    var sessionManager: VimeoSessionManager!
    
    // MARK: 
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: 
    
    private var assets: [VIMPHAsset] = []
    private var cameraRollAssetHelper: PHAssetHelper?
    
    // MARK: Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.cameraRollAssetHelper = PHAssetHelper()
        self.assets = self.loadAssets()
        
        self.setupNavigationBar()
        self.setupCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        self.collectionView.indexPathsForSelectedItems?.forEach({ self.collectionView.deselectItem(at: $0, animated: true) })
    }
    
    // MARK: Setup
    
    private func loadAssets() -> [VIMPHAsset]
    {
        var assets = [VIMPHAsset]()

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .video, options: options)

        fetchResult.enumerateObjects({ (object: AnyObject?, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            
            if let phAsset = object as? PHAsset
            {
                let vimPHAsset = VIMPHAsset(phAsset: phAsset)
                assets.append(vimPHAsset)
            }
        })        
        
        return assets
    }

    private func setupCollectionView()
    {
        let nib = UINib(nibName: DemoCameraRollCell.NibName, bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: DemoCameraRollCell.CellIdentifier)
        
        let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.minimumInteritemSpacing = BaseCameraRollViewController.CollectionViewSpacing
        layout?.minimumLineSpacing = BaseCameraRollViewController.CollectionViewSpacing
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DemoCameraRollCell.CellIdentifier, for: indexPath) as! DemoCameraRollCell
        
        let cameraRollAsset = self.assets[indexPath.item]
        
        self.cameraRollAssetHelper?.requestImage(cell: cell, cameraRollAsset: cameraRollAsset)
        self.cameraRollAssetHelper?.requestAsset(cell: cell, cameraRollAsset: cameraRollAsset)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        let cameraRollAsset = self.assets[indexPath.item] 
        
        self.cameraRollAssetHelper?.cancelRequests(with: cameraRollAsset)
    }
    
    // MARK: UICollectionViewFlowLayoutDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let dimension = (collectionView.bounds.size.width - BaseCameraRollViewController.CollectionViewSpacing) / 2

        return CGSize(width: dimension, height: dimension)
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let asset = self.assets[indexPath.item]
        
        // Check if an error occurred when attempting to retrieve the asset
        
        if let error = asset.error
        {
            self.presentAssetErrorAlert(at: indexPath, error: error)
            
            return
        }
        
        if AFNetworkReachabilityManager.shared().isReachable == false
        {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "The internet connection appears to be offline."])
            self.presentErrorAlert(at: indexPath, error: error)
            
            return
        }
        
        self.didSelect(asset)
    }
    
    // MARK: UI Presentation

    private func presentAssetErrorAlert(at indexPath: IndexPath, error: NSError)
    {
        let alert = UIAlertController(title: "Asset Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            self?.collectionView.reloadItems(at: [indexPath]) // Let the user manually reselect the cell since reload is async
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentErrorAlert(at indexPath: IndexPath, error: NSError)
    {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.collectionView.indexPathsForSelectedItems?.forEach({ strongSelf.collectionView.deselectItem(at: $0, animated: true) })
        }))

        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
        
            guard let strongSelf = self else
            {
                return
            }
            
            strongSelf.collectionView(strongSelf.collectionView, didSelectItemAt: indexPath)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Overrides
    
    func setupNavigationBar()
    {
        self.title = "Camera Roll"
    }

    func didSelect(_ asset: VIMPHAsset)
    {
        assertionFailure("Subclasses must override")
    }
}

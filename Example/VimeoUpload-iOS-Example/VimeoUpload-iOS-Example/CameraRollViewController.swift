//
//  CameraRollViewController.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 10/16/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit
import Photos

class CameraRollViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var tableView: UITableView!
    
    private var phAssets: [PHAsset] = []
    
    // MARK: Lifecycle
    
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
        
        let viewController = VideoSettingsViewController(nibName:"VideoSettingsViewController", bundle:NSBundle.mainBundle())
        viewController.phAsset = phAsset
        
        let navigationController = UINavigationController(rootViewController: viewController)
        
        self.presentViewController(navigationController, animated: true, completion: nil)
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
}

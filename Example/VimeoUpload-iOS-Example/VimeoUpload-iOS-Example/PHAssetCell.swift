//
//  PHAssetCell.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 10/16/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit
import Photos

@available(iOS 8, *)
class PHAssetCell: UITableViewCell
{
    static let CellIdentifier = "PHAssetCellIdentifier"
    
    private var phAssetOperation: PHAssetOperation?

    var phAsset: PHAsset?
    {
        didSet
        {
            if let phAsset = self.phAsset
            {
                self.fetchAVAsset(phAsset)
            }
            else
            {
                self.phAssetOperation?.cancel()
            }
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
     
        self.phAsset = nil
    }
    
    // MARK: Private API
    
    private func fetchAVAsset(phAsset: PHAsset)
    {
        self.phAssetOperation = PHAssetOperation(phAsset: phAsset)
        self.phAssetOperation?.networkAccessAllowed = false
        self.phAssetOperation?.completionBlock = { [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            guard phAsset == strongSelf.phAsset else
            {
                return
            }
            
            if let error = strongSelf.phAssetOperation?.error
            {
                print("Error retrieving PHAsset's AVAsset: \(error.localizedDescription)")
            }
            else if let avAsset = strongSelf.phAssetOperation?.avAsset
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    strongSelf.textLabel?.text = "Duration: \(CMTimeGetSeconds(avAsset.duration))"
                })
            }
            
            strongSelf.phAssetOperation = nil
        }
        
        self.phAssetOperation?.start()
    }

}

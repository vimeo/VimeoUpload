//
//  PHAssetCell.swift
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

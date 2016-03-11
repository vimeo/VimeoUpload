//
//  UploadDescriptor+Retry.swift
//  Smokescreen
//
//  Created by Hanssen, Alfie on 3/9/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import Photos
import AssetsLibrary

extension UploadDescriptor
{
    // MARK: AL & PHAsset Helpers
    
    @available(iOS 8.0, *)
    func phAssetForRetry() -> PHAsset?
    {
        guard let assetIdentifier = self.identifier else
        {
            return nil
        }
        
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localIdentifier = %@", assetIdentifier)
        
        let result = PHAsset.fetchAssetsWithLocalIdentifiers([assetIdentifier], options: options)
        
        return result.firstObject as? PHAsset
    }
    
    @available(iOS 7.0, *)
    func alAssetForRetry() -> ALAsset?
    {
        guard let identifier = self.identifier else
        {
            return nil
        }

        var retrievedAsset: ALAsset?
        
        let url = NSURL(string: identifier)
        
        let semaphore = dispatch_semaphore_create(0)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let library = VIMAssetsLibrary.sharedAssetsLibrary()
            library.assetForURL(url, resultBlock: { (asset) -> Void in
                
                retrievedAsset = asset
                dispatch_semaphore_signal(semaphore)
                
            }) { (error) -> Void in
                
                dispatch_semaphore_signal(semaphore)
            }
        }
        
        let timeoutInSeconds: Double = 5
        let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(timeoutInSeconds * Double(NSEC_PER_SEC)))
        dispatch_semaphore_wait(semaphore, timeout)
        
        return retrievedAsset
    }
}
//
//  AVAsset+Extensions.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AVFoundation

extension AVURLAsset
{
    func fileSize() throws -> NSNumber?
    {
        var value: AnyObject?
    
        try self.URL.getResourceValue(&value, forKey: NSURLFileSizeKey)
    
        guard let number = value as? NSNumber else
        {
            return nil
        }
        
        return number
    }
}
//
//  String+Extensions.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/1/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

extension String
{
    static func stringFromDurationInSeconds(duration: Float64) -> String
    {
        let hours = Int(floor(duration / (60 * 60)))
        
        let minutes = hours > 0 ? Int(floor((duration % (60 * 60)) / 60)) : Int(floor(duration / 60))
        
        let seconds = Int(floor(duration % 60))
        
        var result = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        
        if minutes > 0
        {
            result = minutes < 10 ? "0\(minutes)" + ":\(result)" : "\(minutes)" + ":\(result)"
        }
        else
        {
            result = "00:\(result)"
        }
        
        if hours > 0
        {
            result = hours < 10 ? "0\(hours)" + ":\(result)" : "\(hours)" + ":\(result)"
        }
        else
        {
            result = "00:\(result)"
        }
        
        return result
    }
    
    static func stringFromSize(size: CGSize) -> String
    {
        let width = Int(floor(size.width))
        let height = Int(floor(size.height))
        
        return "\(width)x\(height)"
    }
}
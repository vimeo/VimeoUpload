//
//  VimeoJSONResponseSerializer.swift
//  Pegasus
//
//  Created by Hanssen, Alfie on 10/16/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AFNetworking

class VimeoResponseSerializer: AFJSONResponseSerializer
{
    override init()
    {
        super.init()

        self.acceptableContentTypes = VimeoResponseSerializer.acceptableContentTypes()
        self.readingOptions = .AllowFragments
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: override to parse out Vimeo error
    
    // MARK: Overrides
    
//    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject?
//    {
//        return super.responseObjectForResponse(response, data: data, error: error)
//    }
//    
//    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?) throws -> AnyObject
//    {
//        return try super.responseObjectForResponse(response, data: data)
//    }
    
    // MARK: Private API

    private static func acceptableContentTypes() -> Set<String>
    {
        return Set(
            ["application/json",
            "text/json",
            "text/html",
            "text/javascript",
            "application/vnd.vimeo.*+json"]
        )
    }
}
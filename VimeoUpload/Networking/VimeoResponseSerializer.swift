//
//  VimeoJSONResponseSerializer.swift
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
    
    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?) throws -> AnyObject
    {
        if let httpResponse = response as? NSHTTPURLResponse
        {
            print(httpResponse.allHeaderFields)
        }
        
        return try super.responseObjectForResponse(response, data: data)
    }
    
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
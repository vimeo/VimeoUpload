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

class VimeoResponseSerializer: AFJSONResponseSerializer
{
    static let ErrorDomain = "VimeoResponseSerializerErrorDomain"
    
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
    
    // TODO: override to parse out Vimeo error?
    
    // MARK: Overrides
    
//    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject?
//    {
//        return super.responseObjectForResponse(response, data: data, error: error)
//    }
    
    // MARK: Public API
    
    func checkStatusCode(response: NSURLResponse?, responseObject: AnyObject?) throws
    {
        if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode < 200 || httpResponse.statusCode > 299
        {
            // TODO: populate error object with dictionary contents, keep in sync with localytics keys
            
            let userInfo = [NSLocalizedDescriptionKey: "Invalid http status code for download task"]
            
            throw NSError(domain: UploadErrorDomain.Me.rawValue, code: 0, userInfo: userInfo)
        }
    }
    
    func dictionaryForDownloadTaskResponse(url: NSURL?) throws -> [String: AnyObject]
    {
        guard let url = url else
        {
            throw NSError(domain: VimeoResponseSerializer.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Url for completed download task is nil."])
        }
        
        guard let data = NSData(contentsOfURL: url) else
        {
            throw NSError(domain: VimeoResponseSerializer.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Data at url for completed download task is nil."])
        }
        
        var dictionary: [String: AnyObject]? = [:]
        if data.length > 0
        {
            do
            {
                dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]
            }
            catch let error as NSError
            {
                throw error
            }
        }
        
        if dictionary == nil
        {
            throw NSError(domain: VimeoResponseSerializer.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Download task response dictionary is nil."])
        }
        
        return dictionary!
    }

    // MARK: Private API

    private static func acceptableContentTypes() -> Set<String>
    {
        return Set(
            ["application/json",
            "text/json",
            "text/html",
            "text/javascript",
            "application/vnd.vimeo.*+json",
            "application/vnd.vimeo.user+json",
            "application/vnd.vimeo.video+json"]
        )
    }
}
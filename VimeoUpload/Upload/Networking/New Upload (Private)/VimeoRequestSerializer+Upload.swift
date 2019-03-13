//
//  VimeoRequestSerializer+Upload.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/20/15.
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
import VimeoNetworking

extension VimeoRequestSerializer
{
    private struct Constants
    {
        static let UploadKey = "upload"
    }

    func createVideoRequest(with url: URL, videoSettings: VideoSettings?, uploadParameters: UploadParameters) throws -> NSMutableURLRequest
    {
        // Create a dictionary containing the file size and MIMEType parameters
        let baseUploadParameters = try self.createFileParameters(url: url)
        
        // Merge in the new key-value pairs passed in, favoring new values for any duplicate keys
        let allUploadParameters = baseUploadParameters.merging(uploadParameters) { (current, new) in new }
        
        // Store `uploadParameters` dictionary as the value to "upload" key inside `parameters` dictionary.
        var parameters = [Constants.UploadKey: allUploadParameters as Any]
        
        if let videoSettings = videoSettings
        {
            for (key, value) in videoSettings.parameterDictionary()
            {
                parameters[key] = value
            }
        }

        let url = URL(string: "/me/videos", relativeTo: VimeoBaseURL)!
        
        return try self.createVideoRequest(with: url, parameters: parameters)
    }
}

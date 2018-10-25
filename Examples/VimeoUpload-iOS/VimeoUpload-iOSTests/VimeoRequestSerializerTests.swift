//
//  VimeoRequestSerializerTests.swift
//  VimeoUpload-iOSTests
//
//  Created by Nguyen, Van on 10/25/18.
//  Copyright © 2018 Vimeo. All rights reserved.
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

import XCTest
@testable import VimeoUpload
@testable import VimeoNetworking

class VimeoRequestSerializerTests: XCTestCase
{
    private var serializer: VimeoRequestSerializer?
    private var url: URL
    {
        guard let url = Bundle(for: type(of: self)).url(forResource: "wide_worlds", withExtension: "mp4") else
        {
            fatalError("Error: Cannot get file's URL.")
        }
        
        return url
    }
    
    override func setUp()
    {
        super.setUp()
        
        guard self.serializer == nil else
        {
            return
        }
        
        self.serializer = VimeoRequestSerializer(accessTokenProvider: { () -> String? in
            return "asdf"
        }, apiVersion: "3.3")
    }
    
    func test_createVideoRequest_returnsRequestWithUploadApproachStreaming_whenUploadApproachIsNotSpecified()
    {
        let parameters = self.parameters(fromRequestWithUploadApproach: nil)
        
        XCTAssertEqual(parameters["upload"]?["approach"] as? String, "streaming", "The upload approach should have been \"streaming.\"")
    }
    
    func test_createVideoRequest_returnsRequestWithUploadApproachTus_whenUploadApproachIsTus()
    {
        let parameters = self.parameters(fromRequestWithUploadApproach: .Tus)
        
        XCTAssertEqual(parameters["upload"]?["approach"] as? String, "tus", "The upload approach should have been \"tus.\"")
    }
    
    func test_createVideoRequest_returnsRequestWithUploadApproachPull_whenUploadApproachIsPull()
    {
        let parameters = self.parameters(fromRequestWithUploadApproach: .Pull)
        
        XCTAssertEqual(parameters["upload"]?["approach"] as? String, "pull", "The upload approach should have been \"pull.\"")
    }
    
    func test_createVideoRequest_returnsRequestWithUploadApproachPost_whenUploadApproachIsPost()
    {
        let parameters = self.parameters(fromRequestWithUploadApproach: .Post)
        
        XCTAssertEqual(parameters["upload"]?["approach"] as? String, "post", "The upload approach should have been \"post.\"")
    }
    
    private func parameters(fromRequestWithUploadApproach approach: VIMUpload.UploadApproach?) -> [String: [String: Any]]
    {
        do
        {
            let request: NSURLRequest?
            
            if let approach = approach
            {
                request = try serializer?.createVideoRequest(with: self.url, videoSettings: nil, uploadType: approach)
            }
            else
            {
                request = try serializer?.createVideoRequest(with: self.url, videoSettings: nil)
            }
            
            guard let data = request?.httpBody, let parameters = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: [String: Any]] else
            {
                fatalError("Error: Cannot read request's body.")
            }
            
            return parameters
        }
        catch
        {
            fatalError("Error: Cannot create video request.")
        }
    }
}

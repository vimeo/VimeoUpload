//
//  UploadDescriptorTests.swift
//  VimeoUpload-iOSTests
//
//  Created by Nguyen, Van on 11/13/18.
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
@testable import VimeoNetworking
@testable import VimeoUpload

class UploadDescriptorTests: XCTestCase
{
    func test_uploadLink_returnsStreamingLink_whenStreamingLinkIsAvailable()
    {
        let (descriptor, video) = self.descriptor(fromResponseWithFile: "clip_streaming.json")
        
        XCTAssertEqual(descriptor.uploadLink(from: video), "https://www.google.com", "`uploadLink` should have returned a streaming link.")
    }
    
    func test_uploadLink_returnsGCSLink_whenGCSLinkIsAvailable()
    {
        let (descriptor, video) = self.descriptor(fromResponseWithFile: "clip_gcs.json")
        
        XCTAssertEqual(descriptor.uploadLink(from: video), "https://www.google.com", "`uploadLink` should have returned an GCS link.")
    }
    
    func test_uploadLink_returnsNil_whenNeitherStreamLinkNorGCSLinkIsAvailable()
    {
        let (descriptor, video) = self.descriptor(fromResponseWithFile: "clip.json")
        
        XCTAssertNil(descriptor.uploadLink(from: video), "`uploadLink` should have returned nil.")
    }
    
    private func descriptor(fromResponseWithFile fileName: String) -> (UploadDescriptor, VIMVideo)
    {
        do
        {
            let bundle = Bundle(for: type(of: self))
            
            guard let jsonUrl = bundle.url(forResource: fileName, withExtension: nil), let fileUrl = bundle.url(forResource: "wide_worlds", withExtension: "mp4") else
            {
                fatalError("Error: File not found.")
            }
            
            let data = try Data(contentsOf: jsonUrl)
            
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else
            {
                fatalError("Error: Dictionary object cannot be created.")
            }
            
            let video = try VIMObjectMapper.mapObject(responseDictionary: dictionary) as VIMVideo
            
            let descriptor = UploadDescriptor(url: fileUrl, video: video)
            
            return (descriptor, video)
        }
        catch let error
        {
            fatalError("Error: \(error.localizedDescription)")
        }
    }
}

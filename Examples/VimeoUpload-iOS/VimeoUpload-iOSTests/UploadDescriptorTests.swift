//
//  UploadDescriptorTests.swift
//  VimeoUpload-iOSTests
//
//  Created by Nguyen, Van on 11/13/18.
//  Copyright © 2018 Alfie Hanssen. All rights reserved.
//

import XCTest
import AFNetworking
@testable import VimeoNetworking
@testable import VimeoUpload

class UploadDescriptorTests: XCTestCase
{
    private var urlSessionManager: VimeoSessionManager!
    
    override func setUp()
    {
        super.setUp()
        
        self.urlSessionManager = VimeoSessionManager.defaultSessionManager(appConfiguration: AppConfiguration(clientIdentifier: "", clientSecret: "", scopes: [], keychainService: ""), configureSessionManagerBlock: nil)
    }
    
    override func tearDown()
    {
        self.urlSessionManager?.invalidateSessionCancelingTasks(true)
        
        self.urlSessionManager = nil
    }
    
    func test_uploadLink_returnsStreamingLink_whenStreamingLinkIsAvailable()
    {
        let (descriptor, video) = self.descriptor(fromResponseWithFile: "clip_streaming.json")
        
        XCTAssertEqual(descriptor.uploadLink(from: video), "https://www.google.com")
    }
    
    func test_uploadLink_returnsGCSLink_whenGCSLinkIsAvailable()
    {
        let (descriptor, video) = self.descriptor(fromResponseWithFile: "clip_gcs.json")
        
        XCTAssertEqual(descriptor.uploadLink(from: video), "https://www.google.com")
    }
    
    func test_uploadLink_throwsError_whenNeitherStreamLinkNorGCSLinkIsAvailable()
    {
        
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

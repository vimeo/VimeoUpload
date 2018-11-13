//
//  UploadDescriptorTests.swift
//  VimeoUpload-iOSTests
//
//  Created by Nguyen, Van on 11/13/18.
//  Copyright © 2018 Alfie Hanssen. All rights reserved.
//

import XCTest
import AFNetworking
@testable import VimeoUpload

class UploadDescriptorTests: XCTestCase
{
    private var urlSessionManager: AFURLSessionManager?
    
    override func setUp()
    {
        super.setUp()
        
        let configuration = URLSessionConfiguration.default
        self.urlSessionManager = AFURLSessionManager(sessionConfiguration: configuration)
    }
    
    override func tearDown()
    {
        self.urlSessionManager?.invalidateSessionCancelingTasks(true)
        
        self.urlSessionManager = nil
    }
    
    func test_uploadLink_returnsStreamingLink_whenStreamingLinkIsAvailable()
    {
        
    }
    
    func test_uploadLink_returnsGCSLink_whenGCSLinkIsAvailable()
    {
        
    }
    
    func test_uploadLink_throwsError_whenNeitherStreamLinkNorGCSLinkIsAvailable()
    {
        
    }
}

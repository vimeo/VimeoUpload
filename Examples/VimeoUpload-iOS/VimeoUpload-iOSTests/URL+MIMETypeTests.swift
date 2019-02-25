//
//  URL+MIMETypeTests.swift
//  VimeoUpload-iOSTests
//
//  Created by Lehrer, Nicole on 2/6/19.
//  Copyright © 2019 Alfie Hanssen. All rights reserved.
//

import XCTest

class URL_MIMETypeTests: XCTestCase {

    func test_MIMEType_returnsVideoMP4() {
        let urlMP4 = URL(string: "testFile.mp4")
        XCTAssertTrue(try urlMP4?.mimeType() == "video/mp4")
    }
    
    func test_MIMEType_returnsVideoQuicktime(){
        let urlQuickTime = URL(string: "testFile.mov")
        XCTAssertTrue(try urlQuickTime?.mimeType() == "video/quicktime")
    }
    
    func test_MIMEType_returnsVideoAVI(){
        let urlAVI = URL(string: "testFile.avi")
        XCTAssertTrue(try urlAVI?.mimeType() == "video/avi")
    }
    
    func test_MIMEType_throwsError()
    {
        let urlInvalid = URL(string: "")
        let mimeTypeError = NSError(domain: URL.MIMETypeError.Domain, code: URL.MIMETypeError.Code, userInfo: URL.MIMETypeError.UserInfo)

        do
        {
            _ = try urlInvalid?.mimeType()
        }
        catch let error
        {
            XCTAssertEqual((error as NSError), mimeTypeError)
        }
    }
}

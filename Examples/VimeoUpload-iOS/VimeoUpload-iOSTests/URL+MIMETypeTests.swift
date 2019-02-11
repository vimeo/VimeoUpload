//
//  URL+MIMETypeTests.swift
//  VimeoUpload-iOSTests
//
//  Created by Lehrer, Nicole on 2/6/19.
//  Copyright © 2019 Alfie Hanssen. All rights reserved.
//

import XCTest

class URL_MIMETypeTests: XCTestCase {

    let urlMP4 = URL(string: "testFile.mp4")
    let urlQuickTime = URL(string: "testFile.mov")
    let urlAVI = URL(string: "testFile.avi")

    func test_MIMEType_returnsVideoMP4() {
        XCTAssertTrue(try urlMP4?.mimeType() == "video/mp4")
    }
    
    func test_MIMEType_returnsVideoQuicktime(){
        XCTAssertTrue(try urlQuickTime?.mimeType() == "video/quicktime")
    }
    
    func test_MIMEType_returnsVideoAVI(){
        XCTAssertTrue(try urlAVI?.mimeType() == "video/avi")
    }
}

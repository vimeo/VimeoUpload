//
//  VimeoUpload_iOS_2StepTests.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/29/15.
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

import XCTest
@testable import VimeoUpload_iOS_2Step

class VimeoUpload_iOS_2StepTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFormattedDuration()
    {
        // Seconds
        
        var result = String.stringFromDurationInSeconds(0)
        XCTAssertEqual(result, "00:00:00", "Duration of 0 secs yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(5)
        XCTAssertEqual(result, "00:00:05", "Duration of 5 secs yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(30)
        XCTAssertEqual(result, "00:00:30", "Duration of 30 secs yielded incorrectly formatted string.")
        
        // Minutes
        
        result = String.stringFromDurationInSeconds(60)
        XCTAssertEqual(result, "00:01:00", "Duration of 60 secs yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(300)
        XCTAssertEqual(result, "00:05:00", "Duration of 30 mins yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(1800)
        XCTAssertEqual(result, "00:30:00", "Duration of 30 mins yielded incorrectly formatted string.")
        
        // Hours
        
        result = String.stringFromDurationInSeconds(3600)
        XCTAssertEqual(result, "01:00:00", "Duration of 1 hr yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(18000)
        XCTAssertEqual(result, "05:00:00", "Duration of 5 hrs yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(108000)
        XCTAssertEqual(result, "30:00:00", "Duration of 30 hrs yielded incorrectly formatted string.")
        
        // Minutes and Seconds
        
        result = String.stringFromDurationInSeconds(61)
        XCTAssertEqual(result, "00:01:01", "Duration of 61 secs yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(90)
        XCTAssertEqual(result, "00:01:30", "Duration of 90 secs yielded incorrectly formatted string.")
        
        // Hours and Minutes
        
        result = String.stringFromDurationInSeconds(3660)
        XCTAssertEqual(result, "01:01:00", "Duration of 1 hr 1 min yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(5400)
        XCTAssertEqual(result, "01:30:00", "Duration of 1.5 hrs yielded incorrectly formatted string.")
        
        // Hours and Minutes and Seconds
        
        result = String.stringFromDurationInSeconds(3661)
        XCTAssertEqual(result, "01:01:01", "Duration of 1 hr 1 min 1 sec yielded incorrectly formatted string.")
        
        result = String.stringFromDurationInSeconds(3690)
        XCTAssertEqual(result, "01:01:30", "Duration of 1 hr 1 min 30 secs yielded incorrectly formatted string.")
    }    
}

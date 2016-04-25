//
//  AFURLSessionManager+Extensions.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 12/7/15.
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

extension AFURLSessionManager
{
    // Workaround for iOS7 / iPod bug
    // On iOS7 taskForIdentifier returns nil when casting the identified task to NSURLSessionTask
    // On iOS8 and above the result is non-nil
    // Modifying this method to return AnyObject and cast in the calling class to NSURLSessionData/Download/UploadTask [AH] 1/24/2016

    @available(iOS 7.0, *)
    func taskForIdentifierWorkaround(identifier: Int) -> AnyObject?
    {
        return self.tasks.filter{ $0.taskIdentifier == identifier }.first
    }

    @available(iOS 8.0, *)
    func taskForIdentifier(identifier: Int) -> NSURLSessionTask?
    {
        return self.tasks.filter{ $0.taskIdentifier == identifier }.first
    }
}

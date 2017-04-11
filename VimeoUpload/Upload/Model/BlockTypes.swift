//
//  BlockTypes.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
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

public typealias ProgressBlock = (Double) -> Void
public typealias ErrorBlock = (NSError?) -> Void
public typealias StringErrorBlock = (String?, NSError?) -> Void
public typealias FloatBlock = (Float64) -> Void

public typealias UserCompletionHandler = (VIMUser?, NSError?) -> Void
public typealias VideoCompletionHandler = (VIMVideo?, NSError?) -> Void
public typealias VideosCompletionHandler = ([VIMVideo]?, NSError?) -> Void
public typealias UploadTicketCompletionHandler = (VIMUploadTicket?, NSError?) -> Void

public typealias VideoUri = String
public typealias FileSizeCheckResult = (fileSize: Float64, availableSpace: Float64, success: Bool)

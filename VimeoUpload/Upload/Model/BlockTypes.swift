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

typealias ProgressBlock = (progress: Double) -> Void
typealias ErrorBlock = (error: NSError?) -> Void
typealias StringErrorBlock = (value: String?, error: NSError?) -> Void
typealias FloatBlock = (value: Float64) -> Void

typealias UserCompletionHandler = (user: VIMUser?, error: NSError?) -> Void
typealias VideoCompletionHandler = (video: VIMVideo?, error: NSError?) -> Void
typealias VideosCompletionHandler = (videos: [VIMVideo]?, error: NSError?) -> Void
typealias UploadTicketCompletionHandler = (uploadTicket: VIMUploadTicket?, error: NSError?) -> Void

typealias VideoUri = String
typealias FileSizeCheckResult = (fileSize: Float64, availableSpace: Float64, success: Bool)

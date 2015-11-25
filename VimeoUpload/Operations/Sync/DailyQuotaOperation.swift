//
//  DailyQuotaOperation.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/9/15.
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
import AVFoundation

class DailyQuotaOperation: NSOperation
{
    private static let ErrorDomain = "DailyQuotaOperationErrorDomain"
    
    private let user: VIMUser
    
    private(set) var result: Bool?
    private(set) var error: NSError?
    
    init(user: VIMUser)
    {
        self.user = user
        
        super.init()
    }
    
    // MARK: Overrides

    // Because we haven't yet exported the asset we check against approximate filesize
    // If we can't calculate the available disk space we eval to true beacuse we'll catch any real error later during export

    override func main()
    {
        if let sd = self.user.uploadQuota?.quantityQuota?.canUploadSd, let hd = self.user.uploadQuota?.quantityQuota?.canUploadHd
        {
            self.result = (sd == true && hd == true)
        }
        else
        {
            self.error = NSError(domain: DailyQuotaOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "User object did not contain uploadQuota.quota information"])
        }
    }
    
    override func cancel()
    {
        super.cancel()
    
        print("DailyQuotaOperation cancelled")
    }
}

//
//  DiskSpaceOperation.swift
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

public class DiskSpaceOperation: NSOperation
{    
    private let fileSize: Float64
    
    private(set) var result: FileSizeCheckResult?
    private(set) var error: NSError?

    init(fileSize: Float64)
    {
        self.fileSize = fileSize
    
        super.init()
    }
    
    // MARK: Overrides

    // If we can't calculate the available disk space we eval to true beacuse we'll catch any real error later during export
    
    override public func main()
    {
        do
        {
            if let availableDiskSpace = try NSFileManager.defaultManager().availableDiskSpace()?.doubleValue
            {
                let success = availableDiskSpace > self.fileSize
                self.result = FileSizeCheckResult(fileSize: self.fileSize, availableSpace: availableDiskSpace, success: success)
            }
            else
            {
                self.error = NSError.errorWithDomain(UploadErrorDomain.DiskSpaceOperation.rawValue, code: UploadLocalErrorCode.CannotCalculateDiskSpace.rawValue, description: "File system information did not contain NSFileSystemFreeSize key:value pair")
            }
        }
        catch
        {
            self.error = NSError.errorWithDomain(UploadErrorDomain.DiskSpaceOperation.rawValue, code: UploadLocalErrorCode.CannotCalculateDiskSpace.rawValue, description: "Unable to calculate available disk space")
        }
    }
}
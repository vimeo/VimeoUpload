//
//  NSError+Upload.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/12/15.
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

enum UploadErrorDomain: String
{
    case VimeoUpload = "VimeoUploadErrorDomain"
    case PHAssetExportSession = "PHAssetExportSessionErrorDomain"
    case DailyQuota = "DailyQuotaErrorDomain"
    case WeeklyQuota = "WeeklyQuotaErrorDomain"
    case DiskSpace = "DiskSpaceErrorDomain"
    case Export = "ExportVideoErrorDomain"

    case Me = "MeErrorDomain"
    case MyVideos = "MyVideosErrorDomain"
    case Create = "CreateVideoErrorDomain"
    case Upload = "VideoUploadErrorDomain"
    case Activate = "ActivateVideoErrorDomain"
    case VideoSettings = "VideoSettingsErrorDomain"
    case Delete = "DeleteVideoErrorDomain"
    case Video = "VideoErrorDomain"

    case DiskSpaceOperation = "DiskSpaceOperationErrorDomain"
    case WeeklyQuotaOperation = "WeeklyQuotaOperationErrorDomain"
    case DailyQuotaOperation = "DailyQuotaOperationErrorDomain"
    case RetryUploadOperation = "RetryUploadOperationErrorDomain"
    case ExportQuotaCreateOperation = "ExportQuotaCreateOperationErrorDomain"
    case CreateVideoOperation = "CreateVideoOperationErrorDomain"
    case VideoOperation = "VideoOperationErrorDomain"
    case MeQuotaOperation = "MeQuotaOperationErrorDomain"
    case MeOperation = "MeOperationErrorDomain"
    case PHAssetCloudExportQuotaOperation = "PHAssetCloudExportQuotaOperationErrorDomain"
    case PHAssetExportSessionOperation = "PHAssetExportSessionOperationErrorDomain"
    case PHAssetDownloadOperation = "PHAssetDownloadOperationErrorDomain"
    case ExportOperation = "ExportOperationErrorDomain"
    case DeleteVideoOperation = "DeleteVideoOperationErrorDomain"
    
    case VimeoResponseSerializer = "VimeoResponseSerializerErrorDomain"
}

enum UploadErrorCode: Int
{
    case CannotEvaluateDailyQuota = 0 // "User object did not contain uploadQuota.quota information"
    case CannotCalculateDiskSpace = 1 // "File system information did not contain NSFileSystemFreeSize key:value pair"
    case CannotEvaluateWeeklyQuota = 2 // "User object did not contain uploadQuota.space information"
    case DailyQuotaException = 3
    case WeeklyQuotaException = 4
    case DiskSpaceException = 5
    case ApproximateWeeklyQuotaException = 6
    case ApproximateDiskSpaceException = 7
    case AssetIsNotExportable = 8
}

enum UploadErrorKey: String
{
    case VimeoErrorCode = "vimeo code"
    case VimeoErrorDomain = "vimeo domain"
}

extension NSError
{    
    class func errorWithDomain(domain: String?, code: Int?, description: String?) -> NSError
    {
        var error = NSError(domain: UploadErrorDomain.VimeoUpload.rawValue, code: 0, userInfo: nil)

        if let description = description
        {
            let userInfo = [NSLocalizedDescriptionKey: description]
            error = error.errorByAddingDomain(domain, code: code, userInfo: userInfo)
        }
        else
        {
            error = error.errorByAddingDomain(domain, code: code, userInfo: nil)
        }
        
        return error
    }
    
    func errorByAddingDomain(domain: String) -> NSError
    {
        return self.errorByAddingDomain(domain, code: nil, userInfo: nil)
    }

    func errorByAddingUserInfo(userInfo: [String: AnyObject]) -> NSError
    {
        return self.errorByAddingDomain(nil, code: nil, userInfo: userInfo)
    }
    
    func errorByAddingCode(code: Int) -> NSError
    {
        return self.errorByAddingDomain(nil, code: code, userInfo: nil)
    }

    func errorByAddingDomain(domain: String?, code: Int?, userInfo: [String: AnyObject]?) -> NSError
    {
        let augmentedInfo = NSMutableDictionary(dictionary: self.userInfo)
        
        if let domain = domain
        {
            augmentedInfo[UploadErrorKey.VimeoErrorDomain.rawValue] = domain
        }

        if let code = code
        {
            augmentedInfo[UploadErrorKey.VimeoErrorCode.rawValue] = code
        }

        if let userInfo = userInfo
        {
            augmentedInfo.addEntriesFromDictionary(userInfo)
        }
        
        return NSError(domain: self.domain, code: self.code, userInfo: augmentedInfo as [NSObject: AnyObject])
    }
}

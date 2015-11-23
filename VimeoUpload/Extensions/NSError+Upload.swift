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
    case PHAssetDownload = "PHAssetDownloadErrorDomain"
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

    case CameraRollOperation = "CameraRollOperationErrorDomain"
    case PrepareUploadOperation = "PrepareUploadOperationErrorDomain"
}

extension NSError
{
    func errorByAddingDomain(domain: String) -> NSError
    {
        return self.errorByAddingDomain(domain, userInfo: nil)
    }

    func errorByAddingUserInfo(userInfo: [String: AnyObject]) -> NSError
    {
        return self.errorByAddingDomain(nil, userInfo: userInfo)
    }

    func errorByAddingDomain(domain: String?, userInfo: [String: AnyObject]?) -> NSError
    {
        let augmentedInfo = NSMutableDictionary(dictionary: self.userInfo)
        
        if let domain = domain
        {
            augmentedInfo["vimeo domain"] = domain
        }
        
        if let userInfo = userInfo
        {
            augmentedInfo.addEntriesFromDictionary(userInfo)
        }
        
        return NSError(domain: self.domain, code: self.code, userInfo: augmentedInfo as [NSObject: AnyObject])
    }
}

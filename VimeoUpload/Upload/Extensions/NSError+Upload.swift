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

public enum UploadErrorDomain: String
{
    case PHAssetExportSession = "PHAssetExportSessionErrorDomain"
    case DiskSpace = "DiskSpaceErrorDomain"
    case Export = "ExportVideoErrorDomain"

    case MyVideos = "MyVideosErrorDomain"
    case Create = "CreateVideoErrorDomain"
    case Upload = "VideoUploadErrorDomain"
    case Activate = "ActivateVideoErrorDomain"
    case VideoSettings = "VideoSettingsErrorDomain"
    case Delete = "DeleteVideoErrorDomain"
    case Video = "VideoErrorDomain"

    case DiskSpaceOperation = "DiskSpaceOperationErrorDomain"
    case CreateVideoOperation = "CreateVideoOperationErrorDomain"
    case VideoOperation = "VideoOperationErrorDomain"
    case ExportSessionOperation = "ExportSessionOperationErrorDomain"
    case ExportOperation = "ExportOperationErrorDomain"
    case DeleteVideoOperation = "DeleteVideoOperationErrorDomain"
    
    case VimeoResponseSerializer = "VimeoResponseSerializerErrorDomain"
    
    case CreateThumbnail = "CreateVideoThumbnailErrorDomain"
    case UploadThumbnail = "UploadVideoThumbnailErrorDomain"
    case ActivateThumbnail = "ActivateVideoThumbnailErrorDomain"
}

@objc public enum UploadLocalErrorCode: Int
{
    case cannotCalculateDiskSpace // "File system information did not contain NSFileSystemFreeSize key:value pair"
    case diskSpaceException
    case assetIsNotExportable
}

public enum UploadErrorKey: String
{
    case AvailableSpace = "AvailableSpace"
    case FileSize = "FileSize"
}

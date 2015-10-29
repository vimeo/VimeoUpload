//
//  NSErrorExtensions.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/12/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

enum UploadErrorDomain: String
{
    case Capability = "UploadCapabilityErrorDomain"
    case Export = "ExportVideoErrorDomain"
    case PHAsset = "PHAssetErrorDomain"
    case Create = "CreateVideoErrorDomain"
    case CombinedCreate = "CombinedCreateVideoErrorDomain"
    case Upload = "VideoUploadErrorDomain"
    case Activate = "ActivateVideoErrorDomain"
    case VideoSettings = "VideoSettingsErrorDomain"
    case Descriptor = "DescriptorErrorDomain"
}

enum UploadErrorCode: Int
{
    // Capability
    
    // Export
    
    case AssetNotExportable = 0
    case AssetHasProtectedContent = 1
    case InvalidExportSession = 2
    case NoDiskSpaceAvailable = 3
    case UnableToCalculateAvailableDiskSpace = 4

    // PHAsset
    
    case NilPHAsset = 5

    // Create
    
    case NilCreateDownloadUrl = 6
    case InvalidCreateResponse = 7
    case CreateFileSizeNotAvailable = 8
    case NilCreateResponseData = 9
    case FileLengthUnavailable = 10
    
    // Combined Create
    
    // Upload

    case SourceFileDoesNotExist = 11
    
    // Activate

    case InvalidActivateResponse = 12

    // Video Settings

    case NilVideoUri = 13
    case EmptyVideoSettings = 14

    // Descriptor
    
    case InvalidDescriptorNoTasks = 15
    case CreateResponseWithoutUploadUri = 16
    case CreateResponseWithoutActivateUri = 17
    case ActivateResponseWithoutVideoUri = 18
}

enum UploadErrorDescription: String
{
    // Capability
    
    // Export
    
    case AssetNotExportable = "The asset is not exportable"
    case AssetHasProtectedContent = "The asset has protected content and cannot be exported"
    case InvalidExportSession = "Export session completed with no error and no outputURL"
    case NoDiskSpaceAvailable = "Not enough space on device to export asset"
    case UnableToCalculateAvailableDiskSpace = "Unable to calculate available disk space"

    // PHAsset

    case NilPHAsset = "Request for AVAsset returned no error and no asset"

    // Create
    
    case NilCreateDownloadUrl = "Create returned no error and no download url"
    case InvalidCreateResponse = "Create response body did not contain required key-value pairs"
    case CreateFileSizeNotAvailable = "Unable to retrieve file size for asset"
    case NilCreateResponseData = "Create returned no error but there was no data at the specified url"
    case FileLengthUnavailable = "Unable to retrieve file length from url"

    // Combined Create
    
    // Upload

    case SourceFileDoesNotExist = "Source file does not exist"

    // Activate
    
    case InvalidActivateResponse = "Activate response headers did not contain Location"

    // Video Settings
    
    case NilVideoUri = "Attempt to create videoSettings request with empty videoUri"
    case EmptyVideoSettings = "Attempt to create videoSettings request with empty videoSettings"

    // Descriptor

    case InvalidDescriptorNoTasks = "Attempt to add descriptor with 0 tasks"
    case CreateResponseWithoutUploadUri = "Descriptor's create response does not contain upload uri"
    case CreateResponseWithoutActivateUri = "Descriptor's create response does not contain activate uri"
    case ActivateResponseWithoutVideoUri = "Descriptor's activate response does not contain video uri"
}

extension NSError
{
    static func sourceFileDoesNotExistError() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Upload.rawValue, code: UploadErrorCode.SourceFileDoesNotExist.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.SourceFileDoesNotExist.rawValue]).errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
    }
    
    static func uploadFileLengthNotAvailable() -> NSError
    {
        return NSError(domain: UploadErrorDomain.Upload.rawValue, code: UploadErrorCode.FileLengthUnavailable.rawValue, userInfo: [NSLocalizedDescriptionKey: UploadErrorDescription.FileLengthUnavailable.rawValue]).errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
    }

    // MARK: Convenience error constructors
    
    func errorByAddingDomain(domain: String) -> NSError
    {
        let userInfo = NSMutableDictionary(dictionary: self.userInfo)
        userInfo["VimeoDomain"] = domain
        
        return NSError(domain: self.domain, code: self.code, userInfo: userInfo as [NSObject: AnyObject])
    }
}

//
//  UploadInterfacing.swift
//  VimeoUpload-iOS
//
//  Created by Lehrer, Nicole on 4/25/18.
//  Copyright © 2018 Alfie Hanssen. All rights reserved.
//

/// Describes the properties required to complete an upload
public protocol UploadInterfacing
{
    var viewPrivacy: String? { get }
    var videoURI: String? { get }
    var uploadLink: String? { get }
}

extension VIMVideo: UploadInterfacing
{
    public var viewPrivacy: String?
    {
        return self.privacy?.view
    }
    
    public var videoURI: String?
    {
        return self.uri
    }
    
    public var uploadLink: String?
    {
        return self.upload?.uploadLink
    }
}

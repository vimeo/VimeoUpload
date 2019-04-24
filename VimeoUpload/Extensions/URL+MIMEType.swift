//
//  URL+MIMEType.swift
//  VimeoUpload
//
//  Created by Lehrer, Nicole on 2/4/19.
//

import MobileCoreServices

public extension URL
{
    public struct MIMETypeError
    {
        public static let UserInfo = [NSLocalizedDescriptionKey: "No detectable MIMEType"]
        public static let Domain = "URLExtension.VimeoUpload"
        public static let Code = 0
    }
    
    /// A helper for determining a file's MIMEType
    ///
    /// - Returns: MIMEType as String
    /// - Throws: throws an error if the MIMEType cannot be determined
    public func mimeType() throws -> String {
        
        let error = NSError(domain: MIMETypeError.Domain, code: MIMETypeError.Code, userInfo: MIMETypeError.UserInfo)
        
        guard self.pathExtension.isEmpty == false else {
            throw error
        }

        // From Apple Docs: Creates a uniform type identifier for the type indicated by the specified tag.
        // This is the primary function to use for going from tag (extension/MIMEType/OSType) to uniform type identifier.
        guard let uniformTypeID = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension as NSString, nil) else {
            throw error
        }
        
        // From Apple Docs:  Returns the identified type's preferred tag with the specified tag class as a CFString.
        // This is the primary function to use for going from uniform type identifier to tag.
        guard let mimeType = UTTypeCopyPreferredTagWithClass(uniformTypeID.takeRetainedValue(), kUTTagClassMIMEType) else {
            throw error
        }
        
        return mimeType.takeRetainedValue() as String
    }
}

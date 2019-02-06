//
//  URL+MIMEType.swift
//  VimeoUpload
//
//  Created by Lehrer, Nicole on 2/4/19.
//

import MobileCoreServices

extension URL
{
    /// A helper for determining a file's MIMEType
    ///
    /// - Returns: MIMEType as String
    /// - Throws: throws an error if the MIMEType cannot be determined
    func MIMEType() throws -> String {
        
        let userInfo = [NSLocalizedDescriptionKey: "No detectable MIMEType"]
        let error = NSError(domain: "URLExtension.VimeoUpload", code: 0, userInfo: userInfo)
        
        guard self.pathExtension.isEmpty == false else {
            throw error
        }

        // From Apple Docs: Creates a uniform type identifier for the type indicated by the specified tag.
        // This is the primary function to use for going from tag (extension/MIMEType/OSType) to uniform type identifier.
        guard let uniformTypeID = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension as NSString, nil) else {
            throw error
        }
        
        let retainedUniformTypeID = uniformTypeID.takeRetainedValue()
        
        // From Apple Docs:  Returns the identified type's preferred tag with the specified tag class as a CFString.
        // This is the primary function to use for going from uniform type identifier to tag.
        guard let mimetype = UTTypeCopyPreferredTagWithClass(retainedUniformTypeID, kUTTagClassMIMEType) else {
            throw error
        }
        
        let retainedMimeType = mimetype.takeRetainedValue()
        return retainedMimeType as String
    }
}

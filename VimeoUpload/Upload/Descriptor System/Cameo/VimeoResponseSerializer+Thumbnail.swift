//
//  VimeoResponseSerializer+Thumbnail.swift
//  Cameo
//
//  Created by Westendorf, Michael on 6/23/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import VimeoNetworking
import VimeoUpload

extension VimeoResponseSerializer
{
    func processUploadThumbnailResponse(response: NSURLResponse?, responseObject: AnyObject?, error: NSError?) throws {
        do {
            try self.checkDataResponseForError(response: response, responseObject: responseObject, error: error)
        } catch let error as NSError {
            throw error.errorByAddingDomain(UploadErrorDomain.Upload.rawValue)
        }
    }
    
}

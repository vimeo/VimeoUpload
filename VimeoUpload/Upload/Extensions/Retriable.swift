//
//  Retriable.swift
//  VimeoUpload
//
//  Created by Nguyen, Van on 12/7/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

import Foundation

public protocol Retriable
{
    func shouldRetry(urlResponse: URLResponse?) -> Bool
}

public extension Retriable where Self: Descriptor
{
    func shouldRetry(urlResponse: URLResponse?) -> Bool
    {
        return true
    }
}

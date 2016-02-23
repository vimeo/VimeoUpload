//
//  NSError+Descriptor.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 2/22/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

let DescriptorCancellationErrorCode = 666
let DescriptorErrorDomain = "DescriptorErrorDomain"

extension NSError
{
    static func descriptorCancellationError() -> NSError
    {
        return NSError(domain: DescriptorErrorDomain, code: DescriptorCancellationErrorCode, userInfo: [NSLocalizedDescriptionKey: "User initiated descriptor cancellation."])
    }
    
    func isDescriptorCancellationError() -> Bool
    {
        return self.domain == DescriptorErrorDomain && self.code == DescriptorCancellationErrorCode
    }
}

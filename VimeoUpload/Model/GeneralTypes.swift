//
//  GeneralTypes.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

typealias VoidBlock = () -> Void
typealias ProgressBlock = (progress: Double) -> Void
typealias ErrorBlock = (error: NSError?) -> Void
typealias StringErrorBlock = (value: String?, error: NSError?) -> Void

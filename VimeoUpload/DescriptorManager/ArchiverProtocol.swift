//
//  ArchiverProtocol.swift
//  Pegasus
//
//  Created by Hanssen, Alfie on 10/23/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation

protocol ArchiverProtocol
{
    func loadObjectForKey(key: String) -> AnyObject?
    func saveObject(object: AnyObject, key: String)
}


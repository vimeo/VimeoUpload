//
//  NSKeyedUnarchiver+Migrations.swift
//  VimeoUpload
//
//  Created by Lehrer, Nicole on 4/27/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//

import VimeoNetworking

extension NSKeyedUnarchiver
{
    @objc public static func setLegacyClassNameMigrations()
    {
        // In older version of this project, it's possible that `VIMUploadQuota` was archived as an Objective-C object. It will now be unarchived in Swift.
        // Swift classes include their module name for archiving and unarchiving, whereas Objective-C classes do not. Thus we need to explictly specify the class name here
        // for legacy archived objects. NAL [04/27/2018]
        
        self.setClass(VIMUploadQuota.self, forClassName: "VIMUploadQuota")
    }
}

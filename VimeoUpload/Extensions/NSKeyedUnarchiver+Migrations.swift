//
//  NSKeyedUnarchiver+Migrations.swift
//  VimeoUpload
//
//  Created by Lehrer, Nicole on 4/27/18.
//  Copyright © 2018 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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

//
//  VimeoSessionManager.swift
//  Pegasus
//
//  Created by Alfred Hanssen on 10/17/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AFNetworking

typealias AuthTokenBlock = () -> String

class VimeoSessionManager: AFHTTPSessionManager
{    
    // MARK: Initialization
    
    static let DocumentsURL = NSURL(string: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])!

    convenience init(authToken: String)
    {
        self.init(authTokenBlock: { () -> String in
            return "Bearer \(authToken)"
        })
    }
    
    init(authTokenBlock: AuthTokenBlock)
    {
        let sessionConfiguration: NSURLSessionConfiguration
        
        if #available(iOS 8.0, OSX 10.10, *)
        {
            sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.vimeo.upload")
        }
        else
        {
            sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfiguration("com.vimeo.upload")
        }
        
        super.init(baseURL: VimeoBaseURLString, sessionConfiguration: sessionConfiguration)
        
        self.requestSerializer = VimeoRequestSerializer(authTokenBlock: authTokenBlock)
        self.responseSerializer = VimeoResponseSerializer()
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }    
}

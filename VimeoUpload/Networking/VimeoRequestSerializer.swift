//
//  VimeoJSONRequestSerializer.swift
//  Pegasus
//
//  Created by Hanssen, Alfie on 10/16/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AFNetworking

class VimeoRequestSerializer: AFJSONRequestSerializer
{
    private var authTokenBlock: AuthTokenBlock
    
    // MARK: Initialization 
    
    init(authTokenBlock: AuthTokenBlock, version: String = "3.2")
    {
        self.authTokenBlock = authTokenBlock
        
        super.init()

        self.setValue("application/vnd.vimeo.*+json; version=\(version)", forHTTPHeaderField: "Accept")
        self.writingOptions = .PrettyPrinted
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides
    
    override func requestWithMethod(method: String, URLString: String, parameters: AnyObject?, error: NSErrorPointer) -> NSMutableURLRequest
    {
        var request = super.requestWithMethod(method, URLString: URLString, parameters: parameters, error: error)
       
        request = self.setAuthorizationHeader(request)
        
        return request
    }
    
    override func requestBySerializingRequest(request: NSURLRequest, withParameters parameters: AnyObject?) throws -> NSURLRequest
    {
        let request = try super.requestBySerializingRequest(request, withParameters: parameters)

        var mutableRequest = request.mutableCopy() as! NSMutableURLRequest
        mutableRequest = self.setAuthorizationHeader(mutableRequest)

        return mutableRequest.copy() as! NSURLRequest
    }
    
    override func requestWithMultipartFormRequest(request: NSURLRequest, writingStreamContentsToFile fileURL: NSURL, completionHandler handler: ((NSError?) -> Void)?) -> NSMutableURLRequest
    {
        var request = super.requestWithMultipartFormRequest(request, writingStreamContentsToFile: fileURL, completionHandler: handler)
    
        request = self.setAuthorizationHeader(request)
        
        return request
    }
    
    // MARK: Private API

    private func setAuthorizationHeader(request: NSMutableURLRequest) -> NSMutableURLRequest
    {
        let authHeaderValue = self.authTokenBlock()
        request.setValue(authHeaderValue, forHTTPHeaderField: "Authorization")
        
        return request
    }
}

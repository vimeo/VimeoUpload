//
//  RetryManager.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/23/15.
//  Copyright © 2015 Vimeo. All rights reserved.
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

import Foundation

class DeletionManager
{
    // MARK: 
    
    private let sessionManager: VimeoSessionManager
    private let retryCount: Int
    
    // MARK:
    
    private var deletions: [String: Int] = [:]
    private let operationQueue: NSOperationQueue
    
    // MARK:
    
    // MARK: Initialization
    
    init(sessionManager: VimeoSessionManager, retryCount: Int)
    {
        self.sessionManager = sessionManager
        self.retryCount = retryCount
        
        self.operationQueue = NSOperationQueue()
        self.operationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
    }
    
    // MARK: Public API
    
    func deleteVideoWithUri(uri: String)
    {
        self.deleteVideoWithUri(uri, retryCount: self.retryCount)
    }
    
    // MARK: Private API

    private func deleteVideoWithUri(uri: String, retryCount: Int)
    {
        self.deletions[uri] = retryCount
        
        let operation = DeleteVideoOperation(sessionManager: self.sessionManager, videoUri: uri)
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.cancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    if let response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse where response.statusCode == 404
                    {
                        strongSelf.deletions.removeValueForKey(uri) // The video has already been deleted

                        return
                    }
                    
                    if let retryCount = strongSelf.deletions[uri] where retryCount > 0
                    {
                        let newRetryCount = retryCount - 1
                        strongSelf.deleteVideoWithUri(uri, retryCount: newRetryCount) // Decrement the retryCount and try again
                    }
                    else
                    {
                        strongSelf.deletions.removeValueForKey(uri) // We retried the required number of times, nothing more to do
                    }
                }
                else
                {
                    strongSelf.deletions.removeValueForKey(uri)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    // TODO: cancel all operations on app backgrounded
    // TODO: start all operations on app launch or foregrounded
    // TODO: implement NSCoding, save and load the dictionary at the appropriate times
}
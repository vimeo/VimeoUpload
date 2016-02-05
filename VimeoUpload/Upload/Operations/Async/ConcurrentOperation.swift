//
//  ConcurrentOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/12/15.
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

// This class is a minimally modified version of this gist: https://gist.github.com/calebd/93fa347397cec5f88233

class ConcurrentOperation: NSOperation
{
    // MARK: Types
    
    enum State
    {
        case Ready, Executing, Finished
        
        func keyPath() -> String
        {
            switch self
            {
                case Ready:
                    return "isReady"
                
                case Executing:
                    return "isExecuting"
                
                case Finished:
                    return "isFinished"
            }
        }
    }
    
    // MARK: Properties
    
    var state = State.Ready
    {
        willSet
        {
            self.willChangeValueForKey(newValue.keyPath())
            self.willChangeValueForKey(state.keyPath())
        }
        didSet
        {
            self.didChangeValueForKey(oldValue.keyPath())
            self.didChangeValueForKey(state.keyPath())
        }
    }
    
    // MARK: NSOperation Property Overrides
    
    override var ready: Bool
    {
        return super.ready && self.state == .Ready
    }
    
    override var executing: Bool
    {
        return self.state == .Executing
    }
    
    override var finished: Bool
    {
        return self.state == .Finished
    }
    
    override var asynchronous: Bool
    {
        return true
    }
    
    // MARK: NSOperation Method Overrides
    
    override func start()
    {
        if self.cancelled
        {            
            return
        }
    
        self.state = .Executing

        // Specifically not dispatching the main method call on a background thread,
        // It's the responsibility of the subclass to determine whether this is necessary,
        // E.g. If the operation is parsing JSON then the subclass would dispatch that to a background thread,
        // E.g. If the operation is starting an NSURLSessionTask there's no need because the task itself runs on a background thread,
        // [AH] 11/10/2015
        
        self.main()
    }
    
    override func main()
    {
        fatalError("Subclasses must override main()")
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.state = .Finished
    }
}

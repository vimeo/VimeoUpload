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

open class ConcurrentOperation: Operation
{
    // MARK: Types
    
    public enum State
    {
        case ready, executing, finished
        
        func keyPath() -> String
        {
            switch self
            {
                case .ready:
                    return "isReady"
                
                case .executing:
                    return "isExecuting"
                
                case .finished:
                    return "isFinished"
            }
        }
    }
    
    // MARK: Properties
    
    open var state = State.ready
    {
        willSet
        {
            self.willChangeValue(forKey: newValue.keyPath())
            self.willChangeValue(forKey: state.keyPath())
        }
        didSet
        {
            self.didChangeValue(forKey: oldValue.keyPath())
            self.didChangeValue(forKey: state.keyPath())
        }
    }
    
    // MARK: NSOperation Property Overrides
    
    override open var isReady: Bool
    {
        return super.isReady && self.state == .ready
    }
    
    override open var isExecuting: Bool
    {
        return self.state == .executing
    }
    
    override open var isFinished: Bool
    {
        return self.state == .finished
    }
    
    override open var isAsynchronous: Bool
    {
        return true
    }
    
    // MARK: NSOperation Method Overrides
    
    override open func start()
    {
        if self.isCancelled
        {            
            return
        }
    
        self.state = .executing

        // Specifically not dispatching the main method call on a background thread,
        // It's the responsibility of the subclass to determine whether this is necessary,
        // E.g. If the operation is parsing JSON then the subclass would dispatch that to a background thread,
        // E.g. If the operation is starting an NSURLSessionTask there's no need because the task itself runs on a background thread,
        // [AH] 11/10/2015
        
        self.main()
    }
    
    override open func main()
    {
        fatalError("Subclasses must override main()")
    }
    
    override open func cancel()
    {
        super.cancel()
        
        self.state = .finished
    }
}

//
//  ConcurrentOperation.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/12/15.
//  Copyright © 2015 Vimeo. All rights reserved.
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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] () -> Void in
            self?.main()
        }
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

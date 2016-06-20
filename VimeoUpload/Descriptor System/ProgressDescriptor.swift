//
//  ProgressDescriptor.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 2/2/16.
//  Copyright © 2016 Vimeo. All rights reserved.
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

public class ProgressDescriptor: Descriptor
{
    // MARK:
    
    // We observe progress here via progressObservable because the descriptor is the only object that knows about the progress object's lifecycle
    // If we allow views to observe the progress they wont know exactly when to remove and add observers when the descriptor is
    // suspended and resumed [AH] 12/25/2015
    
    private static let ProgressKeyPath = "fractionCompleted"
    private var progressKVOContext = UInt8()
    dynamic private(set) var progressObservable: Double = 0
    
    var progress: NSProgress?
    {
        willSet
        {
            self.removeObserversIfNecessary()
        }
        
        didSet
        {
            self.addObserversIfNecessary()
        }
    }
    
    // MARK: 
    
    private var observersAdded = false

    // MARK: - Initialization
    
    deinit
    {
        self.removeObserversIfNecessary()
    }

    // MARK: KVO
    
    private func addObserversIfNecessary()
    {
        if let progress = self.progress where self.observersAdded == false
        {
            progress.addObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, options: .New, context: &self.progressKVOContext)

            self.observersAdded = true
        }
    }
    
    private func removeObserversIfNecessary()
    {
        if let progress = self.progress where self.observersAdded == true
        {
            progress.removeObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, context: &self.progressKVOContext)
            
            self.observersAdded = false
        }
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(self.dynamicType.ProgressKeyPath, &self.progressKVOContext):
                self.progressObservable = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0
            default:
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
        }
        else
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}

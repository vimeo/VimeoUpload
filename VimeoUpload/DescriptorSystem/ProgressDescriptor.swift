//
//  ProgressDescriptor.swift
//  Smokescreen
//
//  Created by Alfred Hanssen on 2/2/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import UIKit

class ProgressDescriptor: Descriptor
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
            self.progress?.removeObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, context: &self.progressKVOContext)
        }
        
        didSet
        {
            self.progress?.addObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.progressKVOContext)
        }
    }

    // MARK: - Initialization
    
    deinit
    {
        self.progress = nil
    }

    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
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

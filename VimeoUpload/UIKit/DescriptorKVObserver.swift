//
//  DescriptorKVObserver.swift
//  Vimeo
//
//  Created by Alfred Hanssen on 1/17/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public protocol DescriptorKVObserverDelegate: class
{
    func descriptorStateDidChange(descriptorType descriptorType: VideoDescriptorType, descriptorState: DescriptorState, isCancelled: Bool, descriptorError: NSError?)
    func descriptorProgressDidChange(descriptorType descriptorType: VideoDescriptorType, progress: Double)
}

public class DescriptorKVObserver: NSObject
{
    // MARK:
    
    public weak var delegate: DescriptorKVObserverDelegate?
    
    // MARK: 
    
    private var observersAdded = false
    
    // MARK:
    
    private static let ProgressKeyPath = "progressObservable"
    private static let StateKeyPath = "stateObservable"
    private var progressKVOContext = UInt8()
    private var stateKVOContext = UInt8()
    
    // Ideally this property would conform to a class (ProgressDescriptor) and a protocol (VideoDescriptor)
    // But this is not (yet?) possible, so the VideoDescriptor has a var { get } property to access the progressDescriptor,
    // See http://stackoverflow.com/questions/30495828/swift-property-that-conforms-to-a-protocol-and-class for details [AH] 2/6/2016
    
    public var descriptor: VideoDescriptor?
    {
        willSet
        {
            self.removeObserversIfNecessary()
        }
        
        didSet
        {
            if let descriptor = self.descriptor
            {
                let type = descriptor.type
                let state = descriptor.progressDescriptor.state
                let isCancelled = descriptor.progressDescriptor.isCancelled
                let error = descriptor.progressDescriptor.error
                self.delegate?.descriptorStateDidChange(descriptorType: type, descriptorState: state, isCancelled: isCancelled, descriptorError: error)
            }
            
            self.addObserversIfNecessary()
        }
    }
    
    // MARK: Initialization
    
    deinit
    {
        self.removeObserversIfNecessary()
    }
    
    // MARK: KVO
    
    private func addObserversIfNecessary()
    {
        if let descriptor = self.descriptor where self.observersAdded == false
        {
            descriptor.progressDescriptor.addObserver(self, forKeyPath: self.dynamicType.StateKeyPath, options: .New, context: &self.stateKVOContext)
            descriptor.progressDescriptor.addObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, options: .New, context: &self.progressKVOContext)
            
            self.observersAdded = true
        }
    }
    
    private func removeObserversIfNecessary()
    {
        if let descriptor = self.descriptor where self.observersAdded == true
        {
            descriptor.progressDescriptor.removeObserver(self, forKeyPath: self.dynamicType.StateKeyPath, context: &self.stateKVOContext)
            descriptor.progressDescriptor.removeObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, context: &self.progressKVOContext)
            
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
                
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    
                    guard let strongSelf = self,
                        let descriptor = strongSelf.descriptor else
                    {
                        return
                    }
                    
                    let type = descriptor.type
                    strongSelf.delegate?.descriptorProgressDidChange(descriptorType: type, progress: progress)
                })
                
            case(self.dynamicType.StateKeyPath, &self.stateKVOContext):
                
                let stateRaw = (change?[NSKeyValueChangeNewKey] as? String) ?? DescriptorState.Ready.rawValue;
                let state = DescriptorState(rawValue: stateRaw)!

                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    
                    guard let strongSelf = self,
                        let descriptor = strongSelf.descriptor else
                    {
                        return
                    }
                    
                    let type = descriptor.type
                    let isCancelled = descriptor.progressDescriptor.isCancelled
                    let error = descriptor.progressDescriptor.error
                    strongSelf.delegate?.descriptorStateDidChange(descriptorType: type, descriptorState: state, isCancelled: isCancelled, descriptorError: error)
                })
                
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
//
//  DescriptorKVObserver.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 1/17/16.
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
        if let descriptor = self.descriptor, self.observersAdded == false
        {
            descriptor.progressDescriptor.addObserver(self, forKeyPath: type(of: self).StateKeyPath, options: .new, context: &self.stateKVOContext)
            descriptor.progressDescriptor.addObserver(self, forKeyPath: type(of: self).ProgressKeyPath, options: .new, context: &self.progressKVOContext)
            
            self.observersAdded = true
        }
    }
    
    private func removeObserversIfNecessary()
    {
        if let descriptor = self.descriptor, self.observersAdded == true
        {
            descriptor.progressDescriptor.removeObserver(self, forKeyPath: type(of: self).StateKeyPath, context: &self.stateKVOContext)
            descriptor.progressDescriptor.removeObserver(self, forKeyPath: type(of: self).ProgressKeyPath, context: &self.progressKVOContext)
            
            self.observersAdded = false
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(type(of: self).ProgressKeyPath, .some(&self.progressKVOContext)):
                
                let progress = change?[.newKey] as? Double ?? 0
                
                DispatchQueue.main.async { [weak self] in
                    
                    guard let strongSelf = self,
                        let descriptor = strongSelf.descriptor else
                    {
                        return
                    }
                    
                    let type = descriptor.type
                    strongSelf.delegate?.descriptorProgressDidChange(descriptorType: type, progress: progress)
                }
                
            case(type(of: self).StateKeyPath, .some(&self.stateKVOContext)):
                
                let stateRaw = (change?[.newKey] as? String) ?? DescriptorState.ready.rawValue;
                let state = DescriptorState(rawValue: stateRaw)!
                
                DispatchQueue.main.async { [weak self] in
                    
                    guard let strongSelf = self,
                        let descriptor = strongSelf.descriptor else
                    {
                        return
                    }
                    
                    let type = descriptor.type
                    let isCancelled = descriptor.progressDescriptor.isCancelled
                    let error = descriptor.progressDescriptor.error
                    strongSelf.delegate?.descriptorStateDidChange(descriptorType: type, descriptorState: state, isCancelled: isCancelled, descriptorError: error)
                }
                
            default:
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            }
        }
        else
        {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

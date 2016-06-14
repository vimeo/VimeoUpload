//
//  UploadCell.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/14/15.
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

import UIKit
import VimeoUpload

class UploadCell: UITableViewCell
{
    // MARK:
    
    static let Height: CGFloat = 100
    static let CellIdentifier = "UploadCellIdentifier"
    static let NibName = "UploadCell"

    // MARK: 

    @IBOutlet weak var descriptorStateLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteButton: UIButton!

    // MARK:
    
    private static let ProgressKeyPath = "progressObservable"
    private static let StateKeyPath = "stateObservable"
    private var progressKVOContext = UInt8()
    private var stateKVOContext = UInt8()

    private var observersAdded = false

    private var descriptor: OldUploadDescriptor?
    {
        willSet
        {
            self.removeObserversIfNecessary()
        }
        
        didSet
        {
            if let state = descriptor?.state
            {
                self.updateState(state)
            }
            
            self.addObserversIfNecessary()
        }
    }

    // MARK:
    
    var assetIdentifier: AssetIdentifier?
    {
        didSet
        {
            if let assetIdentifier = self.assetIdentifier
            {
                self.descriptor = OldVimeoUploader.sharedInstance.descriptorForIdentifier(assetIdentifier)
            }
        }
    }
    
    // MARK: - Initialization
    
    deinit
    {
        self.removeObserversIfNecessary()
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.progressView.hidden = true
        self.updateProgress(0)
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
    
        self.progressView.hidden = true
        self.updateProgress(0)
        self.assetIdentifier = nil
        self.descriptor = nil
    }
    
    // MARK: Actions
    
    @IBAction func didTapButton(sender: UIButton)
    {
        if let descriptor = self.descriptor
        {
            OldVimeoUploader.sharedInstance.cancelUpload(descriptor: descriptor)
        }
    }
    
    // MARK: Descriptor Setup
    
    private func updateProgress(progress: Double)
    {
        let width = self.contentView.frame.size.width
        let constant = CGFloat(1 - progress) * width
        self.progressConstraint.constant = constant
    }
    
    private func updateState(state: DescriptorState)
    {
        switch state
        {
        case .Ready:
            self.updateProgress(0)
            self.progressView.hidden = false
            self.deleteButton.setTitle("Cancel", forState: .Normal)
            self.descriptorStateLabel.text = "Ready"
            self.errorLabel.text = ""
        
        case .Executing:
            self.progressView.hidden = false
            self.deleteButton.setTitle("Cancel", forState: .Normal)
            self.descriptorStateLabel.text = "Executing"
            self.errorLabel.text = ""

        case .Suspended:
            self.updateProgress(0)
            self.progressView.hidden = true
            self.deleteButton.setTitle("Cancel", forState: .Normal)
            self.descriptorStateLabel.text = "Suspended"
            self.errorLabel.text = ""
    
        case .Finished:
            self.updateProgress(0)
            self.progressView.hidden = true
            self.deleteButton.setTitle("Delete", forState: .Normal)
            self.descriptorStateLabel.text = "Finished"

            if let error = self.descriptor?.error
            {
                self.errorLabel.text = error.localizedDescription
            }
        }
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

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(self.dynamicType.ProgressKeyPath, &self.progressKVOContext):
                
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    // Set the progress view to visible here so that the view has already been laid out
                    // And therefore the initial state is calculated based on the laid out width of the cell
                    // Doing this in awakeFromNib is too early, the width is incorrect [AH] 11/25/2015
                    self?.progressView.hidden = false
                    self?.updateProgress(progress)
                })
                
            case(self.dynamicType.StateKeyPath, &self.stateKVOContext):
                
                let stateRaw = (change?[NSKeyValueChangeNewKey] as? String) ?? DescriptorState.Ready.rawValue;
                let state = DescriptorState(rawValue: stateRaw)!
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    self?.updateState(state)
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

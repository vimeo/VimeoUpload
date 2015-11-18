//
//  VideoSettingsViewController.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 10/16/15.
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

class VideoSettingsViewController: UIViewController, UITextFieldDelegate
{
    static let NibName = "VideoSettingsViewController"
    
    // MARK: 
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK:
    
    var input: CameraRollViewControllerResult?
    var descriptorManager: DescriptorManager?
    
    // MARK:
    
    var operation: ConcurrentOperation?
    var descriptor: Descriptor?

    // MARK:
    
    var url: NSURL?
    var videoSettings: VideoSettings?

    // MARK:

    // MARK: Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        assert(self.input != nil, "self.input cannot be nil")
        
        self.edgesForExtendedLayout = .None
        
        self.setupNavigationBar()
        self.startOperation()
    }
    
    // MARK: Setup
    
    func startOperation()
    {
        self.operation = self.buildOperation()
        self.operation?.start()
    }
    
    func startUpload()
    {
        self.descriptor = self.buildDescriptor()
        self.descriptorManager!.addDescriptor(self.descriptor!)
    }

    // MARK: Subclass Overrides
    
    func setupNavigationBar()
    {
        self.title = "Video Settings"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload", style: UIBarButtonItemStyle.Done, target: self, action: "didTapUpload:")
    }

    func buildOperation() -> ConcurrentOperation?
    {
        assertionFailure("Subclasses must override this method")
        
        return nil
    }
    
    func buildDescriptor() -> Descriptor?
    {
        assertionFailure("Subclasses must override this method")
        
        return nil
    }

    func didTapUpload(sender: UIBarButtonItem)
    {
        assertionFailure("Subclasses must override this method")
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        self.descriptionTextView.becomeFirstResponder()
        
        return false
    }
    
    // MARK: UI Presentation
    
    func presentOperationErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Operation Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.navigationController?.popViewControllerAnimated(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.startOperation()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func presentDescriptorErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Descriptor Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.navigationController?.popViewControllerAnimated(true)
        }))
        
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            // We start from the beginning (with the operation instead of the descriptor), 
            // Because the exported file was deleted when the upload descriptor failed,
            // We delete it because leaving it up to the API consumer to delete seems a little risky
            self?.startOperation()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

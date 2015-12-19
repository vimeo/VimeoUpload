//
//  UploadsViewController.swift
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

typealias AssetIdentifier = String

class UploadsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    static let NibName = "UploadsViewController"

    // MARK: 
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: 
    
    private var items: [AssetIdentifier] = []
    
    // MARK:
    
    deinit
    {
        self.removeObservers()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tabBarItem.title = "Uploads"
    
        self.addObservers()
        self.setupTableView()
    }
    
    // MARK: Setup
    
    private func setupTableView()
    {
        let nib = UINib(nibName: UploadCell.NibName, bundle: NSBundle.mainBundle())
        self.tableView.registerNib(nib, forCellReuseIdentifier: UploadCell.CellIdentifier)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(UploadCell.CellIdentifier) as! UploadCell
        
        let assetIdentifier = self.items[indexPath.row]
        cell.assetIdentifier = assetIdentifier
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 100
    }
    
    // MARK: Observers
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "descriptorAdded:", name: DescriptorManagerNotification.DescriptorAdded.rawValue, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: DescriptorManagerNotification.DescriptorAdded.rawValue, object: nil)
    }
    
    func descriptorAdded(notification: NSNotification)
    {
        // TODO: should we move this dispatch to within the descriptor manager itself?
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            if let descriptor = notification.object as? Upload1Descriptor
            {
                let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                self.items.insert(descriptor.assetIdentifier, atIndex: indexPath.row)
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        }
    }
}

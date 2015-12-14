//
//  UploadsViewController.swift
//  VimeoUpload-iOS-Example
//
//  Created by Hanssen, Alfie on 12/14/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import UIKit

typealias AssetIdentifier = String

class UploadsViewController: UIViewController, UITableViewDataSource
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
        cell.textLabel?.text = assetIdentifier
        
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
        // TODO: what thread?
        
        if let descriptor = notification.object as? UploadDescriptor
        {
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.items.insert(descriptor.assetIdentifier, atIndex: indexPath.row)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}

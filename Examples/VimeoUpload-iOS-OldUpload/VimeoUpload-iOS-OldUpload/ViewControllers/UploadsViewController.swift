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
import VimeoUpload

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
        
        self.title = "Uploads"
    
        self.addObservers()
        self.setupTableView()
    }
    
    // MARK: Setup
    
    private func setupTableView()
    {
        let nib = UINib(nibName: UploadCell.NibName, bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: UploadCell.CellIdentifier)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: UploadCell.CellIdentifier) as! UploadCell
        
        let assetIdentifier = self.items[indexPath.row]
        cell.assetIdentifier = assetIdentifier
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UploadCell.Height
    }
    
    // MARK: Observers
    
    private func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(DescriptorManagerDelegate.descriptorAdded(_:)), name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorAdded.rawValue), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(DescriptorManagerDelegate.descriptorDidCancel(_:)), name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: nil)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorAdded.rawValue), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: DescriptorManagerNotification.DescriptorDidCancel.rawValue), object: nil)
    }
    
    @objc func descriptorAdded(_ notification: Notification)
    {
        // TODO: should we move this dispatch to within the descriptor manager itself?
        DispatchQueue.main.async { () -> Void in
            
            if let descriptor = notification.object as? OldUploadDescriptor,
                let identifier = descriptor.identifier
            {
                let indexPath = IndexPath(row: 0, section: 0)
                self.items.insert(identifier, at: indexPath.row)
                self.tableView.insertRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    @objc func descriptorDidCancel(_ notification: Notification)
    {
        // TODO: should we move this dispatch to within the descriptor manager itself?
        DispatchQueue.main.async { () -> Void in
            
            if let descriptor = notification.object as? OldUploadDescriptor,
                let identifier = descriptor.identifier,
                let index = self.items.index(of: identifier)
            {
                self.items.remove(at: index)

                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
}

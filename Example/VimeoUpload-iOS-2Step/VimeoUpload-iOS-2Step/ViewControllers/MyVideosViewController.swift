//
//  MyVideosViewController.swift
//  VimeoUpload-iOS-2Step
//
//  Created by Alfred Hanssen on 11/1/15.
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

class MyVideosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    static let NibName = "MyVideosViewController"
    
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl?
    
    private var items: [VIMVideo] = []
    private var task: NSURLSessionDataTask?
    
    deinit
    {
        self.task?.cancel()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = "My Videos"
        
        self.setupTableView()
        self.setupRefreshControl()
        
        self.refreshControl?.beginRefreshing()
        self.refresh()
    }
    
    // MARK: Setup
    
    private func setupTableView()
    {
        let nib = UINib(nibName: VideoCell.NibName, bundle: NSBundle.mainBundle())
        self.tableView.registerNib(nib, forCellReuseIdentifier: VideoCell.CellIdentifier)
    }
    
    private func setupRefreshControl()
    {
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        
        self.tableView.addSubview(self.refreshControl!)
    }
    
    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(VideoCell.CellIdentifier) as! VideoCell

        cell.textLabel?.text = "test"
        
        return cell
    }
    
    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
    // MARK: Actions
    
    func refresh()
    {
        let sessionManager = UploadManager.sharedInstance.sessionManager
        
        do
        {
            self.task = try sessionManager.myVideosDataTask({ [weak self] (videos, error) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    
                    guard let strongSelf = self else
                    {
                        return
                    }
                    
                    strongSelf.task = nil
                    strongSelf.refreshControl?.endRefreshing()
                    
                    if let error = error
                    {
                        strongSelf.presentErrorAlert(error)
                    }
                    else
                    {
                        strongSelf.items = videos!
                        strongSelf.tableView.reloadData()
                    }
                })
            })
            
            self.task?.resume()
        }
        catch let error as NSError
        {
            self.presentErrorAlert(error)
        }
    }
    
    @IBAction func didTapUpload(sender: UIButton)
    {
        let viewController = CameraRollViewController(nibName: CameraRollViewController.NibName, bundle:NSBundle.mainBundle())

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.view.backgroundColor = UIColor.whiteColor()
        
        self.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: Alerts
    
    private func presentErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Refresh Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.refresh()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

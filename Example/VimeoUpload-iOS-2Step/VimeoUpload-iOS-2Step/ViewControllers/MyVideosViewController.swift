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
import AVFoundation

class MyVideosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, VideoCellDelegate
{
    static let NibName = "MyVideosViewController"
    
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl?
    
    private var items: [VIMVideo] = []
    private var task: NSURLSessionDataTask?
    
    deinit
    {
        self.task?.cancel()
        self.removeObservers()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = "My Videos"
        
        self.addObservers()
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
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "uploadInitiated:", name: VideoSettingsViewController.UploadInitiatedNotification, object: nil)
    }
    
    private func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func uploadInitiated(notification: NSNotification)
    {
        if let video = notification.object as? VIMVideo
        {
            self.items.insert(video, atIndex: 0)
            
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
        }
    }
    
    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(VideoCell.CellIdentifier) as! VideoCell

        let video = self.items[indexPath.row]
        cell.delegate = self
        cell.video = video
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 100
    }
    
    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
    // MARK: VideoCellDelegate
    
    func cellDidDeleteVideoWithUri(cell cell: VideoCell, videoUri: String)
    {
        UploadManager.sharedInstance.deleteUpload(videoUri: videoUri)

        if let indexPath = self.indexPathForVideoUri(videoUri)
        {
            self.items.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // TODO: review this doc https://github.vimeows.com/Vimeo/vimeo/wiki/Upload-Server-Response-Codes
    
    func cellDidRetryUploadDescriptor(cell cell: VideoCell, descriptor: SimpleUploadDescriptor)
    {
        // TODO: We'll need to check with Naren's team to see if we can always just attempt to re-put the video file
        // Or if we need to clear it out on the servers first
        
        let operation = CompositeQuotaOperation(sessionManager: ForegroundSessionManager.sharedInstance)
        operation.completionBlock = { [weak self] () -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.cancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    strongSelf.presentUploadRetryErrorAlert(error)
                }
                else
                {
                    // Initiate the retry
                    UploadManager.sharedInstance.retryUpload(descriptor: descriptor)
                    
                    // And then reload the cell so that it reflects the state of the newly retried upload
                    let videoUri = descriptor.uploadTicket.video!.uri!
                    if let indexPath = strongSelf.indexPathForVideoUri(videoUri)
                    {
                        strongSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    }
                }
            })
        }
        operation.shouldCheckDiskSpace = false // We already have an exported asset, no need to check disk space for export
        operation.start()
        
        let url = descriptor.url
        let asset = AVURLAsset(URL: url)
        operation.fulfillSelection(avAsset: asset)
    }
    
    private func indexPathForVideoUri(videoUri: String) -> NSIndexPath?
    {
        for (index, video) in self.items.enumerate()
        {
            if video.uri == videoUri
            {
                return NSIndexPath(forRow: index, inSection: 0)
            }
        }
        
        return nil
    }
    
    // MARK: Actions
    
    func refresh()
    {
        let sessionManager = ForegroundSessionManager.sharedInstance
        
        do
        {
            self.task = try sessionManager.myVideosDataTask(completionHandler: { [weak self] (videos, error) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    
                    guard let strongSelf = self else
                    {
                        return
                    }
                    
                    strongSelf.task = nil
                    strongSelf.refreshControl?.endRefreshing()
                    
                    if let error = error
                    {
                        strongSelf.presentRefreshErrorAlert(error)
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
            self.presentRefreshErrorAlert(error)
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
    
    private func presentRefreshErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Refresh Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { [weak self] (action) -> Void in
            self?.refreshControl?.beginRefreshing()
            self?.refresh()
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func presentUploadRetryErrorAlert(error: NSError)
    {
        let alert = UIAlertController(title: "Retry Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

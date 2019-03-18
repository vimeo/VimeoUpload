//
//  MyVideosViewController.swift
//  VimeoUpload
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
import Photos
import AssetsLibrary
import VimeoNetworking
import VimeoUpload

class MyVideosViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, VideoCellDelegate, VideoRefreshManagerDelegate
{
    static let NibName = "MyVideosViewController"
    
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl?
    
    private var items: [VIMVideo] = []
    private var task: URLSessionDataTask?
    private var videoRefreshManager: VideoRefreshManager?
    
    deinit
    {
        self.videoRefreshManager?.cancelAll()
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
        self.setupVideoRefreshManager()
        
        self.refresh()
    }
    
    // MARK: Setup
    
    private func setupTableView()
    {
        let nib = UINib(nibName: VideoCell.NibName, bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: VideoCell.CellIdentifier)
    }
    
    private func setupRefreshControl()
    {
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(MyVideosViewController.refresh), for: .valueChanged)
        
        self.tableView.addSubview(self.refreshControl!)
    }
    
    private func setupVideoRefreshManager()
    {
        guard let sessionManager = NewVimeoUploader.sharedInstance?.foregroundSessionManager else
        {
            return
        }
        
        self.videoRefreshManager = VideoRefreshManager(sessionManager: sessionManager, delegate: self)
    }
    
    // MARK: Notifications
    
    private func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MyVideosViewController.uploadInitiated(_:)), name: Notification.Name(rawValue: VideoSettingsViewController.UploadInitiatedNotification), object: nil)
    }
    
    private func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: VideoSettingsViewController.UploadInitiatedNotification), object: nil)
    }
    
    @objc func uploadInitiated(_ notification: Notification)
    {
        if let video = notification.object as? VIMVideo
        {
            self.items.insert(video, at: 0)
            
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .top)
            
            self.videoRefreshManager?.refresh(video: video)
        }
    }
    
    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.CellIdentifier) as! VideoCell

        let video = self.items[indexPath.row]
        cell.delegate = self
        cell.video = video
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 100
    }
    
    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
    }
    
    // TODO: review this doc https://github.vimeows.com/Vimeo/vimeo/wiki/Upload-Server-Response-Codes

    // MARK: VideoCellDelegate
    
    func cellDidDeleteVideoWithUri(cell: VideoCell, videoUri: String)
    {
        NewVimeoUploader.sharedInstance?.cancelUpload(videoUri: videoUri)

        if let indexPath = self.indexPath(for: videoUri)
        {
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func cellDidRetryUploadDescriptor(cell: VideoCell, descriptor: UploadDescriptor)
    {
        // TODO: Implement retry
    }
    
    private func indexPath(for videoUri: String) -> IndexPath?
    {
        for (index, video) in self.items.enumerated()
        {
            if video.uri == videoUri
            {
                return IndexPath(row: index, section: 0)
            }
        }
        
        return nil
    }
    
    // MARK: VideoRefreshManagerDelegate
    
    func uploadingStateDidChange(for video: VIMVideo)
    {
        if let uri = video.uri, let indexPath = self.indexPath(for: uri)
        {
            self.items.remove(at: indexPath.row)
            self.items.insert(video, at: indexPath.row)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    // MARK: Actions
    
    @objc func refresh()
    {
        self.refreshControl?.beginRefreshing()

        guard let sessionManager = NewVimeoUploader.sharedInstance?.foregroundSessionManager else
        {
            return
        }
        
        do
        {
            self.videoRefreshManager?.cancelAll()
            
            self.task = try sessionManager.myVideosDataTask(completionHandler: { [weak self] (videos, error) -> Void in
                
                DispatchQueue.main.async(execute: { [weak self] () -> Void in
                    
                    guard let strongSelf = self else
                    {
                        return
                    }
                    
                    strongSelf.task = nil
                    strongSelf.refreshControl?.endRefreshing()
                    
                    if let error = error
                    {
                        strongSelf.presentRefreshErrorAlert(with: error)
                    }
                    else
                    {
                        strongSelf.items = videos!
                        strongSelf.tableView.reloadData()
                        
                        // Schedule video refreshes
                        for video in strongSelf.items
                        {
                            if video.videoStatus == .uploading || video.videoStatus == .transcoding
                            {
                                strongSelf.videoRefreshManager?.refresh(video: video)
                            }
                        }
                    }
                })
            })
            
            self.task?.resume()
        }
        catch let error as NSError
        {
            self.presentRefreshErrorAlert(with: error)
        }
    }
    
    @IBAction func didTapUpload(_ sender: UIButton)
    {
        PHPhotoLibrary.requestAuthorization { status in
            
            DispatchQueue.main.async(execute: { () -> Void in

                switch status
                {
                case .authorized:
                    let viewController = CameraRollViewController(nibName: BaseCameraRollViewController.NibName, bundle:Bundle.main)
                    let navigationController = UINavigationController(rootViewController: viewController)
                    navigationController.view.backgroundColor = UIColor.white
                    self.present(navigationController, animated: true, completion: nil)

                case .restricted:
                    print("Unable to present camera roll. Camera roll access restricted.")
                case .denied:
                    print("Unable to present camera roll. Camera roll access denied.")
                default:
                    // place for .NotDetermined - in this callback status is already determined so should never get here
                    break
                }

            })
        }
    }
    
    // MARK: Alerts
    
    private func presentRefreshErrorAlert(with error: NSError)
    {
        let alert = UIAlertController(title: "Refresh Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { [weak self] (action) -> Void in
            self?.refresh()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func presentUploadRetryErrorAlert(with error: NSError)
    {
        let alert = UIAlertController(title: "Retry Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
}

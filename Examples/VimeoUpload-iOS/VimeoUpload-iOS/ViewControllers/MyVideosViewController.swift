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
    fileprivate var refreshControl: UIRefreshControl?
    
    fileprivate var items: [VIMVideo] = []
    fileprivate var task: URLSessionDataTask?
    fileprivate var videoRefreshManager: VideoRefreshManager?
    
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
    
    fileprivate func setupTableView()
    {
        let nib = UINib(nibName: VideoCell.NibName, bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: VideoCell.CellIdentifier)
    }
    
    fileprivate func setupRefreshControl()
    {
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.addTarget(self, action: #selector(MyVideosViewController.refresh), for: .valueChanged)
        
        self.tableView.addSubview(self.refreshControl!)
    }
    
    fileprivate func setupVideoRefreshManager()
    {
        self.videoRefreshManager = VideoRefreshManager(sessionManager: NewVimeoUploader.sharedInstance.foregroundSessionManager, delegate: self)
    }
    
    // MARK: Notifications
    
    fileprivate func addObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(MyVideosViewController.uploadInitiated(_:)), name: NSNotification.Name(rawValue: VideoSettingsViewController.UploadInitiatedNotification), object: nil)
    }
    
    fileprivate func removeObservers()
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: VideoSettingsViewController.UploadInitiatedNotification), object: nil)
    }
    
    func uploadInitiated(_ notification: NSNotification)
    {
        if let video = notification.object as? VIMVideo
        {
            self.items.insert(video, at: 0)
            
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .top)
            
            self.videoRefreshManager?.refreshVideo(video)
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
        NewVimeoUploader.sharedInstance.cancelUpload(videoUri: videoUri)

        if let indexPath = self.indexPathForVideoUri(videoUri)
        {
            self.items.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func cellDidRetryUploadDescriptor(cell: VideoCell, descriptor: UploadDescriptor)
    {
        let videoUri = descriptor.uploadTicket.video!.uri!

        self.retryUploadDescriptor(descriptor, completion: { [weak self] (error) in
         
            guard let strongSelf = self else
            {
                return
            }
            
            if error != nil
            {
                return
            }
            
            // Reload the cell so that it reflects the state of the newly retried upload
            if let indexPath = strongSelf.indexPathForVideoUri(videoUri)
            {
                strongSelf.tableView.reloadRows(at: [indexPath], with: .none)
            }
        })
    }
    
    fileprivate func indexPathForVideoUri(_ videoUri: String) -> IndexPath?
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
    
    func uploadingStateDidChangeForVideo(_ video: VIMVideo)
    {
        if let uri = video.uri, let indexPath = self.indexPathForVideoUri(uri)
        {
            self.items.remove(at: indexPath.row)
            self.items.insert(video, at: indexPath.row)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    // MARK: Actions
    
    func refresh()
    {
        self.refreshControl?.beginRefreshing()

        let sessionManager = NewVimeoUploader.sharedInstance.foregroundSessionManager
        
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
                        strongSelf.presentRefreshErrorAlert(error)
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
                                strongSelf.videoRefreshManager?.refreshVideo(video)
                            }
                        }
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
    
    fileprivate func presentRefreshErrorAlert(_ error: NSError)
    {
        let alert = UIAlertController(title: "Refresh Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: { [weak self] (action) -> Void in
            self?.refresh()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func presentUploadRetryErrorAlert(_ error: NSError)
    {
        let alert = UIAlertController(title: "Retry Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Private API
    
    fileprivate func retryUploadDescriptor(_ descriptor: UploadDescriptor, completion: ErrorBlock)
    {
        // TODO: This should be cancellable

//        guard let phAsset = descriptor.phAssetForRetry() else
//        {
//            return
//        }
//        
//        let operation = PHAssetRetryUploadOperation(sessionManager: UploadManager.sharedInstance.foregroundSessionManager, phAsset: phAsset)
//
//        operation.downloadProgressBlock = { (progress: Double) -> Void in
//            print("Download progress (settings): \(progress)") // TODO: Dispatch to main thread
//        }
//        
//        operation.exportProgressBlock = { (progress: Double) -> Void in
//            print("Export progress (settings): \(progress)")
//        }
//        operation.completionBlock = { [weak self] () -> Void in
//            
//            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
//                
//                guard let strongSelf = self else
//                {
//                    return
//                }
//                
//                if operation.cancelled == true
//                {
//                    return
//                }
//                
//                if let error = operation.error
//                {
//                    strongSelf.presentUploadRetryErrorAlert(error)
//                }
//                else
//                {
//                    // Initiate the retry
//
//                    let url = operation.url!
//                    UploadManager.sharedInstance.retryUpload(descriptor: descriptor, url: url)
//                }
//                
//                completion(error: operation.error)
//            })
//        }
//        
//        operation.start()
    }
}

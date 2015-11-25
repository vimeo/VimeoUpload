//
//  VideoCell.swift
//  VimeoUpload
//
//  Created by Alfred Hanssen on 11/23/15.
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

protocol VideoCellDelegate: class
{
    func cellDidDeleteVideoWithUri(cell cell: VideoCell, videoUri: String)
}

class VideoCell: UITableViewCell
{
    // MARK:
    
    static let CellIdentifier = "VideoCellIdentifier"
    static let NibName = "VideoCell"
    
    // MARK:

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var progressConstraint: NSLayoutConstraint!
    @IBOutlet weak var button: UIButton!
    
    // MARK:

    private static let ProgressKeyPath = "fractionCompleted"
    private var progressKVOContext = UInt8()
    private var progress: NSProgress?
    {
        willSet
        {
            self.progress?.removeObserver(self, forKeyPath: VideoCell.ProgressKeyPath, context: &self.progressKVOContext)
        }
        
        didSet
        {
            self.progress?.addObserver(self, forKeyPath: VideoCell.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.progressKVOContext)
        }
    }
    
    // MARK: 
    weak var delegate: VideoCellDelegate?
    var video: VIMVideo?
    {
        didSet
        {
            self.progress = nil

            if let video = self.video
            {
                self.setupImageView(video)
                self.setupLabel(video)
                self.progress = UploadManager.sharedInstance.uploadProgressForVideoUri(video.uri!)
            }
        }
    }
    
    // MARK:

    deinit
    {
        self.video = nil
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.updateProgress(1)
        self.updateButton(0)
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
    
        self.video = nil
        self.thumbnailImageView?.image = nil
        self.statusLabel.text = ""

        self.updateProgress(1)
        self.updateButton(0)
    }
    
    // MARK: Actions
    
    @IBAction func didTapButton(sender: UIButton)
    {
        if let videoUri = self.video?.uri
        {
            self.progress = nil
            self.updateProgress(0)
            
            UploadManager.sharedInstance.cancelUploadWithVideoUri(videoUri)
            
            self.delegate?.cellDidDeleteVideoWithUri(cell: self, videoUri: videoUri)
        }
    }
    
    // MARK: Private API
    
    private func setupImageView(video: VIMVideo)
    {
        let width = Float(self.thumbnailImageView.frame.size.width * UIScreen.mainScreen().scale)
        if let picture = video.pictureCollection?.pictureForWidth(width), let link = picture.link, let url = NSURL(string: link)
        {
            self.thumbnailImageView.setImageWithURL(url)
        }
    }
    
    private func setupLabel(video: VIMVideo)
    {
        self.statusLabel.text = video.status
    }
    
    private func updateProgress(progress: Double)
    {
        let hidden = (progress <= 0 || progress >= 1)
        self.progressView.hidden = hidden

        let width = self.contentView.frame.size.width
        let constant = CGFloat(1 - progress) * width
        
        self.progressConstraint.constant = constant
    }

    private func updateButton(progress: Double)
    {
        let cancellable = (progress > 0 && progress < 1)
        if cancellable == true
        {
            self.button.setTitle("Cancel", forState: .Normal)
        }
        else
        {
            self.button.setTitle("Delete", forState: .Normal)
        }
    }

    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(VideoCell.ProgressKeyPath, &self.progressKVOContext):
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    self?.updateProgress(progress)
                    self?.updateButton(progress)
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

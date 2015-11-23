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
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
    
        self.video = nil
        self.thumbnailImageView?.image = nil
        self.statusLabel.text = ""
        self.progressView.hidden = true
        self.progressConstraint.constant = 0
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
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(VideoCell.ProgressKeyPath, &self.progressKVOContext):
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                print("Cell progress: \(progress)")
                
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

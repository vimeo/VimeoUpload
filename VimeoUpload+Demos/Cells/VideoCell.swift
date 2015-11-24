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
    
    // MARK:

    var video: VIMVideo?
    {
        didSet
        {
            if let video = self.video
            {
                let width = Float(self.thumbnailImageView.frame.size.width * UIScreen.mainScreen().scale)
                if let picture = video.pictureCollection?.pictureForWidth(width), let link = picture.link, let url = NSURL(string: link)
                {
                    self.setupImageView(url)
                }
                
                let status = video.videoStatus
                self.setupLabel(status)
            }
        }
    }
    
    // MARK:
    
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
    }
    
    // MARK: Private API
    
    private func setupImageView(url: NSURL)
    {
        self.thumbnailImageView.setImageWithURL(url)
    }
    
    private func setupLabel(status: VIMVideoProcessingStatus)
    {
        self.statusLabel.text = self.video?.status
    }
}

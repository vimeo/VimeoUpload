//
//  CameraRollCell.swift
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

class CameraRollCell: UICollectionViewCell
{
    static let CellIdentifier = "CameraRollCellIdentifier"
    static let NibName = "CameraRollCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var durationlabel: UILabel!
    @IBOutlet weak var gradientView: VIMGradientView!
    
    override var selected: Bool
    {
        didSet
        {
            if selected == true
            {
                self.imageView.alpha = 0.5
            }
            else
            {
                self.imageView.alpha = 1.0
            }
        }
    }
    
    // MARK: Overrides
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    
        self.clear()
        
        self.gradientView.setColors(topColor: UIColor.clearColor(), bottomColor: UIColor.blackColor().colorWithAlphaComponent(0.5))
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()

        self.clear()
    }
    
    // MARK: Private API
    
    private func clear()
    {
        self.imageView.image = nil
        self.fileSizeLabel.text = ""
        self.durationlabel.text = ""
    }
    
    // MARK: Public API
    
    func setImage(image: UIImage)
    {
        self.imageView.image = image
    }
    
    func setDuration(seconds seconds: Float64)
    {
        self.durationlabel?.text = String.stringFromDurationInSeconds(seconds) as String
    }
    
    func setFileSize(bytes bytes: Float64)
    {
        let string = NSString.stringFromFileSize(bytes: bytes)
        self.fileSizeLabel.text = string as String
    }

    func setInCloud()
    {
        self.fileSizeLabel.text = NSLocalizedString("iCloud", comment: "")
    }
}

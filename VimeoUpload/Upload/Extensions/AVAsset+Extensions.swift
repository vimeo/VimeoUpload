//
//  AVAsset+Extensions.swift
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

import Foundation
import AVFoundation

public extension AVAsset
{    
    func approximateFileSize(completion: FloatBlock)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in

            var approximateSize: Float64 = 0
            
            let tracks = self.tracks // Accessing the tracks property is slow, maybe synchronous below the hood, so dispatching to bg thread
            for track in tracks
            {
                let dataRate: Float = track.estimatedDataRate
                let bytesPerSecond = dataRate / Float(8)
                let seconds: Float64 = CMTimeGetSeconds(track.timeRange.duration)
                approximateSize += seconds * Float64(bytesPerSecond)
            }

            assert(approximateSize > 0, "Unable to calculate approximate fileSize")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(value: approximateSize)
            })
        }
    }
}
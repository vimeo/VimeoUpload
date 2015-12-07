//
//  AVAssetExportOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
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

#if os(iOS)
    import MobileCoreServices
#elseif os(OSX)
    import CoreServices
#endif

class AVAssetExportOperation: ConcurrentOperation
{
    private static let ErrorDomain = "AVAssetExportOperationErrorDomain"
    
    private static let ProgressKeyPath = "progress"
    private static let FileType = AVFileTypeMPEG4
    private static let DocumentsURL = NSURL(string: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])!

    private var exportSession: AVAssetExportSession
    
    // We KVO on this internally in order to call the progressBlock, see note below as to why [AH] 10/22/2015
    private dynamic var progress: Float = 0
    private var exportProgressKVOContext = UInt8()
    var progressBlock: ProgressBlock?
    
    private(set) var outputURL: NSURL?
    private(set) var error: NSError?
    
    // MARK: Initialization
    
    convenience init(asset: AVAsset)
    {
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        
        self.init(exportSession: exportSession)
    }

    init(exportSession: AVAssetExportSession)
    {
        // exportSession.timeRange must be valid so that the exportSession's estimatedOutputFileLength is non zero
        // We use estimatedOutputFileLength below to check that there is ample disk space to perform the export [AH] 10/15/2015
        
        exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, exportSession.asset.duration)

        assert(CMTIMERANGE_IS_EMPTY(exportSession.timeRange) == false, "exportSession.timeRange is empty")
        assert(CMTIMERANGE_IS_INDEFINITE(exportSession.timeRange) == false, "exportSession.timeRange is indefinite")
        assert(CMTIMERANGE_IS_INVALID(exportSession.timeRange) == false, "exportSession.timeRange is invalid")
        assert(CMTIMERANGE_IS_VALID(exportSession.timeRange) == true, "exportSession.timeRange is not valid")
        assert(CMTIME_IS_POSITIVEINFINITY(exportSession.timeRange.duration) == false, "exportSession.timeRange.duration is infinite")
        
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = AVAssetExportOperation.FileType

        do
        {
            var url = AVAssetExportOperation.DocumentsURL.URLByAppendingPathComponent("uploader")
            url = url.URLByAppendingPathComponent("video_files")
            exportSession.outputURL = try url.vimeoUploadExportURL(fileType: AVAssetExportOperation.FileType)
        }
        catch let error as NSError
        {
            fatalError("Error creating upload export directory: \(error.localizedDescription)")
        }

        self.exportSession = exportSession
        
        super.init()
        
        self.addObservers()
    }
    
    deinit
    {
        self.removeObservers()
        self.progressBlock = nil
        self.exportSession.cancelExport()
    }

    // MARK: Overrides

    override func main()
    {
        if self.cancelled
        {
            return
        }
        
        if self.exportSession.asset.exportable == false
        {
            self.error = NSError(domain: AVAssetExportOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Asset is not exportable"])
            self.state = .Finished
            
            return
        }

        // AVAssetExportSession does not do an internal check to see if there's ample disk space available to perform the export [AH] 12/06/2015
        
        let availableDiskSpace = try? NSFileManager.defaultManager().availableDiskSpace() // Double optional
        if let diskSpace = availableDiskSpace, let space = diskSpace where space.longLongValue < self.exportSession.estimatedOutputFileLength
        {
            self.error = NSError(domain: AVAssetExportOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Not enough disk space to copy asset"])
            self.state = .Finished
            
            return
        }
        
        self.exportSession.exportAsynchronouslyWithCompletionHandler({ [weak self] () -> Void in
            
            guard let strongSelf = self else
            {
                return
            }
            
            if strongSelf.cancelled
            {
                return
            }
            
            if let error = strongSelf.exportSession.error
            {
                strongSelf.error = error
            }
            else if let outputURL = strongSelf.exportSession.outputURL, let path = outputURL.path where NSFileManager.defaultManager().fileExistsAtPath(path)
            {
                strongSelf.outputURL = outputURL
            }
            else
            {
                strongSelf.error = NSError(domain: AVAssetExportOperation.ErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Export session finished with no error and no output URL."])
            }

            strongSelf.state = .Finished
        })

        // For some reason, not sure why, KVO on self.exportSession.progress does not trigger calls to observeValueForKeyPath
        // So I'm using this while loop to update a dynamic property instead, and KVO'ing on that [AH] 10/22/2015
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) { [weak self] () -> Void in
            while self?.exportSession.status == AVAssetExportSessionStatus.Waiting || self?.exportSession.status == AVAssetExportSessionStatus.Exporting
            {
                self?.progress = self?.exportSession.progress ?? 0
            }
        }
    }
    
    override func cancel()
    {
        super.cancel()
        
        self.progressBlock = nil
        self.exportSession.cancelExport()
    }
        
    // MARK: KVO
    
    private func addObservers()
    {
        self.addObserver(self, forKeyPath: AVAssetExportOperation.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.exportProgressKVOContext)
    }
    
    private func removeObservers()
    {
        self.removeObserver(self, forKeyPath: AVAssetExportOperation.ProgressKeyPath, context: &self.exportProgressKVOContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
                case(AVAssetExportOperation.ProgressKeyPath, &self.exportProgressKVOContext):
                    let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0;
                    self.progressBlock?(progress: progress)
                
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

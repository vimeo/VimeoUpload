//
//  ExportVideoOperation.swift
//  VIMUpload
//
//  Created by Hanssen, Alfie on 10/13/15.
//  Copyright © 2015 Vimeo. All rights reserved.
//

import Foundation
import AVFoundation

#if os(iOS)
    import MobileCoreServices
#elseif os(OSX)
    import CoreServices
#endif

class ExportVideoOperation: ConcurrentOperation
{
    private static let ProgressKeyPath = "progress"
    private static let FileType = AVFileTypeMPEG4
    private static let DocumentsURL = NSURL(string: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])!

    private var exportSession: AVAssetExportSession
    
    // We KVO on this internally in order to call the progressBlock, see note below as to why [AH] 10/22/2015
    private dynamic var progress: Float = 0
    private var exportProgressKVOContext = UInt8()
    var progressBlock: ProgressBlock?
    
    private(set) var outputURL: NSURL?
    {
        didSet
        {
            if self.outputURL != nil
            {
                self.state = .Finished
            }
        }
    }
    
    private(set) var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .Finished
            }
        }
    }
    
    // MARK: Initialization

    deinit
    {
        self.removeObservers()
        self.progressBlock = nil
        self.exportSession.cancelExport()
    }
    
    convenience init(asset: AVAsset, presetName: String = AVAssetExportPresetPassthrough, baseOutputURL: NSURL = ExportVideoOperation.DocumentsURL)
    {
        let exportSession = AVAssetExportSession(asset: asset, presetName: presetName)! // Assert if this produces nil [AH] 10/15/2015
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = ExportVideoOperation.FileType
        
        do
        {
            exportSession.outputURL = try baseOutputURL.vimeoUploadExportURL(ExportVideoOperation.FileType)
        }
        catch let error as NSError
        {
            assertionFailure("Error creating upload export directory: \(error.localizedDescription)")
        }
        
        exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        self.init(exportSession: exportSession)
    }

    init(exportSession: AVAssetExportSession)
    {
        // timeRange must be valid so that the exportSession's estimatedOutputFileLength is non zero
        // We use estimatedOutputFileLength below to check that there is ample disk space to perform the export [AH] 10/15/2015
        
        assert(CMTIMERANGE_IS_VALID(exportSession.timeRange) && CMTIMERANGE_IS_EMPTY(exportSession.timeRange) == false && CMTIMERANGE_IS_INDEFINITE(exportSession.timeRange) == false, "AVAssetExportSession is configured with invalid timeRange")
        
        self.exportSession = exportSession
        
        super.init()
        
        self.addObservers()
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
            self.error = NSError.assetNotExportableError()
            
            return
        }

        if self.exportSession.asset.hasProtectedContent == true
        {
            self.error = NSError.assetHasProtectedContentError()
            
            return
        }
        
        let fileLength = NSNumber(longLong: self.exportSession.estimatedOutputFileLength) // TODO: Is this value reliable? [AH]
        let freeDiskSpace = try? NSFileManager.defaultManager().freeDiskSpace()
        guard let aFreeDiskSpace = freeDiskSpace else
        {
            self.error = NSError.unableToCalculateAvailableDiskSpaceError()
            
            return
        }
        
        // TODO: get rid of all of these error objects and just use an ErrorType enum that's a simple numeric code?
        
        if let space = aFreeDiskSpace where fileLength.unsignedLongLongValue > 0 && space.unsignedLongLongValue < fileLength.unsignedLongLongValue
        {
            self.error = NSError.noDiskSpaceAvailableError()
            
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
            
            assert(strongSelf.exportSession.status == AVAssetExportSessionStatus.Completed, "Export did not complete")
            
            if let error = strongSelf.exportSession.error
            {
                strongSelf.error = error.errorByAddingDomain(UploadErrorDomain.Export.rawValue)
            }
            else if let outputURL = strongSelf.exportSession.outputURL, let path = outputURL.path where NSFileManager.defaultManager().fileExistsAtPath(path)
            {
                strongSelf.outputURL = outputURL
            }
            else
            {
                strongSelf.error = NSError.invalidExportSessionError()
            
                assertionFailure(strongSelf.error!.localizedDescription)
            }
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

        self.deleteFile(self.outputURL)
    }
    
    // MARK: Private API
        
    private func deleteFile(url: NSURL?)
    {
        if let url = url where NSFileManager.defaultManager().fileExistsAtPath(url.absoluteString)
        {
            do
            {
                try NSFileManager.defaultManager().removeItemAtPath(url.absoluteString)
            }
            catch let error as NSError
            {
                assertionFailure("Error removing exported file \(error)")
            }
        }
    }
    
    // MARK: KVO
    
    private func addObservers()
    {
        self.addObserver(self, forKeyPath: ExportVideoOperation.ProgressKeyPath, options: NSKeyValueObservingOptions.New, context: &self.exportProgressKVOContext)
    }
    
    private func removeObservers()
    {
        self.removeObserver(self, forKeyPath: ExportVideoOperation.ProgressKeyPath, context: &self.exportProgressKVOContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
                case(ExportVideoOperation.ProgressKeyPath, &self.exportProgressKVOContext):
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

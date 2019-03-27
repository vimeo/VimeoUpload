//
//  ExportSessionExportCreateVideoOperation.swift
//  VimeoUpload
//
//  Created by Hanssen, Alfie on 12/22/15.
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
import VimeoNetworking
import Photos

@objc open class ExportSessionExportCreateVideoOperation: ConcurrentOperation
{
    let sessionManager: VimeoSessionManager
    let operationQueue: OperationQueue
    
    // MARK:

    @objc open var downloadProgressBlock: ProgressBlock?
    @objc open var exportProgressBlock: ExportProgressBlock?
    
    // MARK:
    
    private let phAsset: PHAsset
    private let documentsFolderURL: URL?
    private let uploadParameters: UploadParameters

    @objc open var url: URL?
    @objc open var video: VIMVideo?
    @objc open var videoSettings: VideoSettings?
    @objc open var error: NSError?
    {
        didSet
        {
            if self.error != nil
            {
                self.state = .finished
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes an instance of `ExportSessionExportCreateVideoOperation`.
    ///
    /// - Parameters:
    ///   - phAsset: An instance of `PHAsset` representing a media that the
    ///   user picks from the Photos app.
    ///   - sessionManager: An instance of `VimeoSessionManager` that will
    ///   be used for creating an upload ticket.
    ///   - videoSettings: An instance of `VideoSettings` representing the
    ///   title, description, and privacy option that the user has edited.
    ///   - documentsFolderURL: An URL pointing to a Documents folder;
    ///   default to `nil`. For third-party use, this argument should not be
    ///   filled.
    ///   - uploadParameters: A dictionary of parameters used for the create
    ///   video request.
    @objc public init(phAsset: PHAsset, sessionManager: VimeoSessionManager, videoSettings: VideoSettings? = nil, documentsFolderURL: URL? = nil, uploadParameters: UploadParameters = VimeoSessionManager.Constants.DefaultUploadParameters)
    {
        self.phAsset = phAsset
        
        self.sessionManager = sessionManager
        self.videoSettings = videoSettings
        
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
        
        self.documentsFolderURL = documentsFolderURL

        self.uploadParameters = uploadParameters
        
        super.init()
    }
    
    deinit
    {
        self.operationQueue.cancelAllOperations()
    }
    
    // MARK: Overrides
    
    @objc override open func main()
    {
        if self.isCancelled
        {
            return
        }
        
        let operation = ExportSessionExportOperation(phAsset: self.phAsset, documentsFolderURL: self.documentsFolderURL)
        self.perform(exportSessionExportOperation: operation)
    }
    
    @objc override open func cancel()
    {
        super.cancel()
        
        self.operationQueue.cancelAllOperations()
        
        if let url = self.url
        {
            FileManager.default.deleteFile(at: url)
        }
    }
    
    // MARK: Private API

    private func perform(exportSessionExportOperation operation: ExportSessionExportOperation)
    {
        operation.downloadProgressBlock = { [weak self] (progress: Double) -> Void in
            self?.downloadProgressBlock?(progress)
        }
        
        operation.exportProgressBlock = { [weak self] (exportSession: AVAssetExportSession, progress: Double) -> Void in
            self?.exportProgressBlock?(exportSession, progress)
        }
        
        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    strongSelf.error = error
                }
                else
                {
                    let url = operation.result!
                    strongSelf.createVideo(url: url)
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
    
    private func createVideo(url: URL)
    {
        let videoSettings = self.videoSettings
        
        let operation = CreateVideoOperation(sessionManager: self.sessionManager, url: url, videoSettings: videoSettings, uploadParameters: self.uploadParameters)

        operation.completionBlock = { [weak self] () -> Void in
            
            DispatchQueue.main.async(execute: { [weak self] () -> Void in
                
                guard let strongSelf = self else
                {
                    return
                }
                
                if operation.isCancelled == true
                {
                    return
                }
                
                if let error = operation.error
                {
                    var userInfo = error.userInfo
                    
                    let asset = AVURLAsset(url: url)
                    
                    if let fileSize = try? asset.fileSize()
                    {
                        userInfo.append([UploadErrorKey.FileSize.rawValue : fileSize])
                    }
                    
                    strongSelf.error = NSError(domain: error.domain, code: error.code, userInfo: userInfo)
                }
                else
                {
                    strongSelf.url = url
                    strongSelf.video = operation.result!
                    strongSelf.state = .finished
                }
            })
        }
        
        self.operationQueue.addOperation(operation)
    }
}

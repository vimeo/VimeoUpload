# VimeoUpload

This library is under active development. We're shooting for a v1.0 release in March 2016. All comments, questions, pull requests, and issues are welcome. See below for a draft spec and for information on contributing.

## Contents
* [Design Considerations](#design-considerations)
      * [New Upload, Old Upload](#new-upload-old-upload)
      * [Constraints](#constraints)
      * [Goals](#goals)
* [Getting Started](#getting-started)
      * [CocoaPods](#cocoapods)
      * [Submodule](#submodule)
      * [Initialization](#initialization)
* [Uploading Videos](#uploading-videos)
     * [Starting an Upload](#starting-an-upload)
          * [Obtaining a File URL For a PHAsset](#obtaining-a-file-url-for-a-phasset)
          * [Obtaining a File URL For an ALAsset](#obtaining-a-file-url-for-an-alasset)
          * [Obtaining a File URL For an Asset That You Manage](#obtaining-a-file-url-for-an-asset-that-you-manage)
          * [Obtaining an Upload Ticket](#obtaining-an-upload-ticket)
          * [Start Your Upload](#start-your-upload)
     * [Inspecting Upload State and Progress](#inspecting-upload-state-and-progress)
     * [Canceling an Upload](#canceling-an-upload)
* [Custom Workflows](#custom-workflows)
* [Want to Contribute?](#want-to-contribute)
* [Found an Issue?](#found-an-issue)
* [Questions](#questions)
* [License](#license)

## Design Considerations

### New Upload, Old Upload

1. **Complex Server-side API** The current server-side Vimeo upload API is comprised of 4 separate requests that must be made in sequence. This is more complex than we'd like it to be, and this complexity is not ideal for native mobile clients. More requests means more failure points. More steps means a process that's challenging to communicate to the user. The 4 requests are: (1) create a video object, (2) video file upload, (3) activate video object, (4) optionally set the video object's metadata (e.g. title, description, privacy, etc.)

### Constraints

1. **iOS 7 Support Required** Therefore we must support both the [ALAsset](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/) and [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) APIs.

1. **No Direct File Access for Photos** We cannot upload directly from [ALAsset](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/) and [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) source files. So we must export a copy of the asset using an [AVAssetExportSession](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVAssetExportSession_Class/index.html) before starting the upload process. Asset export must happen when the app is in the foreground.

1. **iCloud Photos Support** If a [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) is in iCloud and not resident on device we need to download it to the device before asset export. Download must happen when the app is in the foreground.

1. **Background Session Required** Because an upload can take a significant amount of time, we must design for the user backgrounding the application at any point in the process. Therefore all requests must be handled by an [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) configured with a background [NSURLSessionConfiguration](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionConfiguration_class/index.html). This means we must rely exclusively on the [NSURLSessionDelegate](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionDelegate_protocol/index.html), [NSURLSessionTaskDelegate](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionTaskDelegate_protocol/index.html#//apple_ref/occ/intf/NSURLSessionTaskDelegate), and [NSURLSessionDownloadDelegate](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionDownloadDelegate_protocol/index.html#//apple_ref/occ/intf/NSURLSessionDownloadDelegate) protocols. We cannot rely on an [NSURLSessionTask](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionTask_class/index.html) subclasses' completion blocks.

1. **Fault Tolerance** The app process could be backgrounded, terminated, or crash at any time. This means that we need to persist the state of the upload system to disk so that it can be reconstructed as needed. Crashes should not adversely impact uploads or the upload system.

1. **Concurrent File Uploads** We want to be able to conduct concurrent uploads.

1. **State Introspection** We want to be able to communicate upload progress and state to the user in a variety of locations.  Including communicating state for uploads initiated on other devices and other platforms.

1. **Reachability Awareness** The app could lose connectivity at any time. We want to be able to pause and resume the upload system when we lose connectivity. And we want to be able to allow the user to restrict uploads to wifi.

1. **Upload Quotas** We need to be able to communicate information to users about their [upload quota](https://vimeo.com/help/faq/uploading-to-vimeo/uploading-basics). 

1. **iOS SDK Quirks** We can't rely on NSURLSessionTask's `suspend` method. TODO: Explain why. We need `taskForIdentifierWorkaround`. TODO: Explain why.

### Goals

1. A simplified server-side upload API that collapses the current 4 steps into 1 or 2 steps.

1. An upload system that accommodates / addresses each point listed above.

1. Clear and concise upload system initialization, management, and introspection.

1. An upload system that accommodates as many UX futures as possible.

## Getting Started
### CocoaPods
### Submodule
### Initialization

Create an instance of `VimeoUpload`, or modify `VimeoUpload` to act as a singleton: 

```Swift
    let backgroundSessionIdentifier = "YOUR_BACKGROUND_SESSION_ID"
    let authToken = "YOUR_OAUTH_TOKEN"
    
    let vimeoUpload = VimeoUpload(backgroundSessionIdentifier: backgroundSessionIdentifier, authToken: authToken)
```

If your OAuth token can change during the course of a session, use the constructor whose second argument is an `authTokenBlock`:

```Swift
    let backgroundSessionIdentifier = "YOUR_BACKGROUND_SESSION_ID"
    var authToken = "YOUR_OAUTH_TOKEN"

    let vimeoUpload = VimeoUpload(backgroundSessionIdentifier: backgroundSessionIdentifier, authTokenBlock: { () -> String? in
        return authToken 
    })
```

You can obtain an OAuth token by using the authentication methods provided by [VIMNetworking](https://github.com/vimeo/VIMNetworking) or by visiting [developer.vimeo.com](https://developer.vimeo.com/apps) and creating a new "app" and associated OAuth token.

## Uploading Videos

### Starting an Upload

In order to start an upload, you need two pieces of information:

1. A file URL pointing to the video file on disk that you would like to upload, and
2. An upload ticket obtained from the Vimeo API

The steps required to obtain the file URL will vary depending on whether you are uploading a [PHAsset](#obtaining-a-file-url-for-a-phasset), an [ALAsset](#obtaining-a-file-url-for-an-alasset), or an [asset that you manage](#obtaining-a-file-url-for-an-asset-that-you-manage) outside of the device Photos environment. Once you have a valid file URL, you will use it to [obtain an upload ticket](#obtaining-an-upload-ticket). Then you can [start your upload](#start-your-upload).

Unfortunately, because of how Apple's [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) and [ALAsset](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/) APIs are designed uploading directly from a [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) or [ALAsset](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/) resource URL is not possible. In order to upload [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html)s and [ALAsset](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/)s you will need to first create a copy of the asset itself and upload from that copy. See below for instructions on how to do this. 

#### Obtaining a File URL For a PHAsset

Use VimeoUpload's `PHAssetExportSessionOperation` to request an instance of [AVAssetExportSession](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVAssetExportSession_Class/index.html) configured for the [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) that you intend to upload. If the [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) is in iCloud (i.e. not resident on the device) this will download the [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) from iCloud. 

```Swift 
    let phAsset = ... // The PHAsset you intend to upload
    let operation = PHAssetExportSessionOperation(phAsset: phAsset)
    
    // Optionally set a progress block
    operation.progressBlock = { (progress: Double) -> Void in
        // Do something with progress
    }
    
    operation.completionBlock = {
        guard operation.cancelled == false else
        {
            return
        }

        if let error = operation.error
        {
            // Do something with the error
        }
        else if let exportSession = operation.result
        {
            // Use the export session to export a copy of the asset (see below)
        }
        else
        {
            assertionFailure("error and exportSession are mutually exclusive. This should never happen.")
        }
    }

    operation.start()
```

Next, use VimeoUpload's `ExportOperation` to export a copy of the [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html). You can then use the resulting `url` to [obtain an upload ticket](#obtaining-an-upload-ticket).

```Swift
    let exportSession = ... // The export session you just generated (see above)
    let operation = ExportOperation(exportSession: exportSession)
    
    // Optionally set a progress block
    operation.progressBlock = { (progress: Double) -> Void in
        // Do something with progress
    }
    
    operation.completionBlock = {
        guard operation.cancelled == false else
        {
            return
        }

        if let error = operation.error
        {
            // Do something with the error
        }
        else if let url = operation.outputURL
        {
            // Use the url to generate an upload ticket (see below)
        }
        else
        {
            assertionFailure("error and outputURL are mutually exclusive, this should never happen.")
        }
    }
    
    operation.start()
```

#### Obtaining a File URL For an ALAsset

Use VimeoUpload's `ExportOperation` to export a copy of the [ALAsset](https://developer.apple.com/library/ios/documentation/AssetsLibrary/Reference/ALAssetsLibrary_Class/) you intend to upload. You can then use the resulting `url` to [obtain an upload ticket](#obtaining-an-upload-ticket).

```Swift
    let alAsset = ... // The ALAsset you intend to upload
    let url = alAsset.defaultRepresentation().url() // For example
    let avAsset = AVURLAsset(URL: url)
    let operation = ExportOperation(asset: avAsset)
    
    // Optionally set a progress block
    operation.progressBlock = { (progress: Double) -> Void in
        // Do something with progress
    }
    
    operation.completionBlock = {
        guard operation.cancelled == false else
        {
            return
        }

        if let error = operation.error
        {
            // Do something with the error
        }
        else if let url = operation.outputURL
        {
            // Use the url to generate an upload ticket (see below)
        }
        else
        {
            assertionFailure("error and outputURL are mutually exclusive, this should never happen.")
        }
    }
    
    operation.start()
```

#### Obtaining a File URL For an Asset That You Manage

This is quite a bit simpler: 

```Swift
    let path = "PATH_TO_VIDEO_FILE_ON_DISK"
    let url = NSURL.fileURLWithPath(path)
```

#### Obtaining an Upload Ticket 

Request an upload ticket from the [Vimeo API](https://developer.vimeo.com/). VimeoUpload provides a simple mechanism by which to make this request. First, create an instance of `VimeoSessionManager`:

```Swift
    let authToken = "YOUR_OAUTH_TOKEN"
    let sessionManager = VimeoSessionManager.defaultSessionManager(authToken: authToken)
```

If your OAuth token can change during the course of a session, use the constructor that takes an `authTokenBlock` argument:

```Swift
    let authToken = "YOUR_OAUTH_TOKEN"
    let sessionManager = VimeoSessionManager.defaultSessionManager(authTokenBlock: { () -> String? in
        return authToken 
    })
```

Then make the request: 

```Swift
    do
    {
        let task = try sessionManager.createVideoDataTask(url: url, videoSettings: nil, completionHandler: { (uploadTicket, error) -> Void in
            
            if let error = error
            {
                // The upload ticket request failed
            }
            else if let uploadTicket = uploadTicket else
            {
                // Use your url and uploadTicket to start your upload (see below)
            }
            else
            {
                assertionFailure("error and uploadTicket are mutually exclusive, this should never happen.")
            }
        })
        
        task.resume()
    }
    catch let error as NSError
    {
        // An error was thrown while attempting to construct the task
    }
```

You can read more about this request [here](https://developer.vimeo.com/api/upload/videos#generate-an-upload-ticket). 

#### Start Your Upload

Use the `url` and `uploadTicket` to start your upload: 

```Swift
    let vimeoUpload = ... // Your instance of VimeoUpload (see above)
    let url = ... // Your url (see above)
    let uploadTicket = ... // Your upload ticket (see above)
    
    vimeoUpload.uploadVideo(url: url, uploadTicket: uploadTicket)
```

The `uploadVideo(url: uploadTicket:)` method returns an instance of `UploadDescriptor`. You can use this to [inspect state and progress](#inspecting-upload-state-and-progress), or to [cancel the upload](#canceling-an-upload).

### Inspecting Upload State and Progress

You can examine upload state and progress by inspecting the `stateObservable` and `progressObservable` properties of an `UploadDescriptor`. 

You can obtain a reference to a specific `UploadDescriptor` by holding onto the `UploadDescriptor` returned from your call to `uploadVideo(url: uploadTicket:)`, or by asking `VimeoUpload` for a specific `UploadDescriptor` like so:

```Swift
    let uploadTicket = ... // Your upload ticket (see above)
    if let videoUri = uploadTicket.video?.uri
    {
        let vimeoUpload = ... // Your instance of VimeoUpload (see above)
        let descriptor = vimeoUpload.descriptorForVideo(videoUri: videoUri)
    }
```

You can also ask `VimeoUpload` for an `UploadDescriptor` that passes a test that you construct. You can construct any test you'd like. You might consider setting `descriptor.identifier` to a value meaningful to you before you start your upload (e.g. set it to a PHAsset `localIdentifier`). That way you can leverage `descriptor.identifier` inside `descriptorPassingTest`:

```Swift
    let phAsset = ... // The PHAsset whose upload you'd like to inspect
    let vimeoUpload = ... // Your instance of VimeoUpload (see above)
    
    let descriptor = vimeoUpload.descriptorManager.descriptorPassingTest({ (descriptor) -> Bool in
        return descriptor.identifier == phAsset.localIdentifier   
    })
```

Once you have a reference to the `UploadDescriptor` you're interested in you can inspect its state directly:

```Swift
    print(descriptor.state)
    print(descriptor.error?.localizedDescription)
```

Or use KVO to observe changes to its state and progress: 

```Swift
    private static let ProgressKeyPath = "progressObservable"
    private static let StateKeyPath = "stateObservable"
    private var progressKVOContext = UInt8()
    private var stateKVOContext = UInt8()

    ...
    
    descriptor.addObserver(self, forKeyPath: self.dynamicType.StateKeyPath, options: .New, context: &self.stateKVOContext)
    descriptor.addObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, options: .New, context: &self.progressKVOContext)
    
    ...
    
    descriptor.removeObserver(self, forKeyPath: self.dynamicType.StateKeyPath, context: &self.stateKVOContext)
    descriptor.removeObserver(self, forKeyPath: self.dynamicType.ProgressKeyPath, context: &self.progressKVOContext)

    ...
    
    // MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if let keyPath = keyPath
        {
            switch (keyPath, context)
            {
            case(self.dynamicType.ProgressKeyPath, &self.progressKVOContext):
                
                let progress = change?[NSKeyValueChangeNewKey]?.doubleValue ?? 0
                
                // Do something with progress                

            case(self.dynamicType.StateKeyPath, &self.stateKVOContext):
                
                let stateRaw = (change?[NSKeyValueChangeNewKey] as? String) ?? DescriptorState.Ready.rawValue;
                let state = DescriptorState(rawValue: stateRaw)!
                
                // Do something with state
                
            default:
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            }
        }
        else
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
```

### Canceling an Upload

Canceling an upload will cancel the file upload itself as well as delete the video object from Vimeo servers. You can cancel an upload using the `UploadDescriptor` instance in question:

```Swift
    let vimeoUpload = ... // Your instance of VimeoUpload (see above)
    let descriptor = ... // The descriptor you'd like to cancel
    
    vimeoUpload.cancelUpload(descriptor: descriptor)
```

Or by using the `videoUri` of the `uploadTicket` you used to create the upload: 

```Swift
    if let videoUri = uploadTicket.video?.uri
    {
        let vimeoUpload = ... // Your instance of VimeoUpload (see above)
        vimeoUpload.cancelUpload(videoUri: videoUri)
    }
```

## Custom Workflows

TBD

## Want to Contribute?

If you'd like to contribute, please follow our guidelines found in [CONTRIBUTING](CONTRIBUTING.md).

## Found an Issue?

Please file any and all issues found in this library to the git [issue tracker](https://github.com/vimeo/vimeoupload/issues).

## Questions?

Tweet at us here: [@vimeoapi](https://twitter.com/vimeoapi).

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`.

Get in touch [here](https://Vimeo.com/help/contact).

## License

`VimeoUpload` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

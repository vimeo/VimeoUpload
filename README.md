# VimeoUpload

This library is under active development. We're shooting for a v1.0 release in March 2016. All comments, questions, pull requests, and issues are welcome. See below for a draft spec and for information on contributing.

## Contents
* [Draft Spec](#draft-spec)
      * [Context](#context)
      * [Target](#target)
* [Getting Started](#getting-started)
      * [CocoaPods](#cocoapods)
      * [Submodule](#submodule)
      * [Initialization](#initialization)
      * [Authentication](#authentication)
* [Uploading Videos](#uploading-videos)
     * [Starting an Upload](#starting-an-upload)
     * [Canceling an Upload](#canceling-an-upload)
     * [Tracking Upload State and Progress](#tracking-upload-state-and-progress)
     * [Additional Configuration](#additional-configuration)
* [Want to Contribute?](#want-to-contribute)
* [Found an Issue?](#found-an-issue)
* [Questions](#questions)
* [License](#license)

## Draft Spec

### Context

1. **Complex Server-side API** The current server-side Vimeo upload API is comprised of 4 separate requests that must be made in sequence. This is more complex than we'd like it to be, and this complexity is not ideal for native mobile clients. More requests means more failure points. More steps means a process that's challenging to communicate to the user. The 4 requests are: (1) create a video object, (2) video file upload, (3) activate video object, (4) optionally set the video object's metadata (e.g. title, description, privacy, etc.)

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

### Target

1. An upload system that accommodates / addresses each point listed above.

1. A revised server-side Vimeo upload API that collapses the current 4 steps into 1 or 2 steps.

1. Clear and concise upload system initialization, management, and introspection.

1. An upload system that accommodates as many UX futures as possible.

## Getting Started
### CocoaPods
### Submodule
### Initialization

Create an instance, perhaps a singleton instance, of `VimeoUpload`: 

```Swift
    let backgroundSessionIdentifier = "YOUR_BACKGROUND_SESSION_ID"
    let authToken = "YOUR_AUTH_TOKEN"
    
    let vimeoUpload = VimeoUpload(backgroundSessionIdentifier: backgroundSessionIdentifier, authToken: authToken)
```

If your auth token may change, use the constructor whose second argument is an `authTokenBlock`:

```
    let vimeoUpload = VimeoUpload(backgroundSessionIdentifier: backgroundSessionIdentifier, authTokenBlock: { () -> String? in
        return authToken 
    })
```

You can obtain an auth token by using the authentication methods provided by [VIMNetworking](https://github.com/vimeo/VIMNetworking) or by visiting [developer.vimeo.com](https://developer.vimeo.com/apps) and creating a new "app" and associated auth token.

## Uploading Videos
### Initiating an Upload

```Swift
    let phAsset: PHAsset = ...
    let assetIdentifier = phAsset.localIdentifier 

    let path = "PATH_TO_VIDEO_FILE_ON_DISK"
    let url = NSURL.fileURLWithPath(path)
    
    let uploadTicket: VIMUploadTicket = ...
    
    vimeoUpload.uploadVideo(url: url, uploadTicket: uploadTicket, assetIdentifier: assetIdentifier) // Note to self: make assetId optional
```

### Canceling an Upload

### Tracking Upload State and Progress
### Additional Configuration

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

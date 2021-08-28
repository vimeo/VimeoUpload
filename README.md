⚠️⚠️⚠️ This library has been deprecated and will be removed in the future. ⚠️⚠️⚠️

# VimeoUpload [![](https://circleci.com/gh/vimeo/VimeoUpload.png?style=shield&circle-token=2e7f762969ca311fc851e32d6ef2038f797f7e23)](https://circleci.com/gh/vimeo/VimeoUpload)

## Contents
* [Getting Started](#getting-started)
     * [Installation](#installation)
     * [Prerequisites](#prerequisites)
     * [Setup your Submodules](#setup-your-submodules)
* [Uploading Videos](#uploading-videos)
* [Locating your uploaded video on Vimeo](#locating-your-uploaded-video-on-vimeo)
* [Notable Constraints](#notable-constraints)
* [Want to Contribute?](#want-to-contribute)
* [Found an Issue?](#found-an-issue)
* [Troubleshooting](#troubleshooting)
* [Questions](#questions)
* [License](#license)


## Getting Started

### Installation

VimeoUpload is available through [Carthage](https://github.com/carthage/Carthage) and coming soon [CocoaPods](http://cocoapods.org) 

### Cocoapods

To install it, simply add the following line to your Podfile:

```ruby
pod "VimeoUpload"
```

### Carthage

Add the following to your Cartfile:

```
github "vimeo/VimeoUpload"
```

### Prerequisites

1. Ensure that you've verified your Vimeo account. When you create an account, you'll receive an email asking that you verify your account. **Until you verify your account you will not be able to upload videos using the API**. 
2. Ensure you have been granted permission to use the "upload" scope. This permission must explicitly be granted by Vimeo API admins. You can request this permission on your "My Apps" page under "Request upload access". Visit [developer.vimeo.com](https://developer.vimeo.com/).
3. Ensure that the OAuth token that you're using to make your requests has the "upload" scope included.
4. In order to run this project, **you will have to insert a valid OAuth token where it says `"YOUR_OAUTH_TOKEN"`. You can obtain an OAuth token by visiting [developer.vimeo.com](https://developer.vimeo.com/apps) and creating a new "app" and associated OAuth token. Without a valid OAuth token, you will be presented with a "Request failed: unauthorized (401)" error alert when you try to upload a video.


### Setup your Submodules

If you are adding this library to your own project, follow the steps outlined in [Getting Started with Submodules as Development Pods](https://paper.dropbox.com/doc/Getting-Started-with-Submodules-as-Development-Pods-yRpNbPxIOjzGlcEbecuOC). 

## Uploading Videos

Please refer to the example projects for a demonstration of how VimeoUpload can be used to upload videos to Vimeo.

## Locating your uploaded video on Vimeo

One can access a video's URL by inspecting the link property on the video that's associated with the upload descriptor: `descriptor.video.link`. 

## Notable Constraints

* **iCloud Photos** 

 If a [PHAsset](https://developer.apple.com/library/prerelease/ios/documentation/Photos/Reference/PHAsset_Class/index.html) is in iCloud and not resident on device we need to download it to the device before asset export. Download must happen when the app is in the foreground.

* **Background Sessions** 

 Because an upload can take a significant amount of time, we must design for the user potentially backgrounding the application at any point in the process. Therefore all requests must be handled by an [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) configured with a background [NSURLSessionConfiguration](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionConfiguration_class/index.html). This means we must rely exclusively on the [NSURLSessionDelegate](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionDelegate_protocol/index.html), [NSURLSessionTaskDelegate](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionTaskDelegate_protocol/index.html#//apple_ref/occ/intf/NSURLSessionTaskDelegate), and [NSURLSessionDownloadDelegate](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionDownloadDelegate_protocol/index.html#//apple_ref/occ/intf/NSURLSessionDownloadDelegate) protocols. We cannot rely on an [NSURLSessionTask](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionTask_class/index.html) subclasses' completion blocks.
 
* **Resumable Uploads**

 The [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/) API does not support resuming an interrupted background upload from an offset. The initial release of this library will use these APIs exclusively and therefore will also not support resuming an upload from an offset. 

## Found an Issue?

If you find any bugs or technical issues with this library, please [create an issue](https://github.com/vimeo/VimeoUpload/issues) and provide relevant code snippets, specific details about the issue, and steps to replicate behavior.

## Troubleshooting

If you have any questions about using this library, please [contact us directly](https://help.vimeo.com), post in the [Vimeo API Forum](https://vimeo.com/forums/api), or check out [StackOverflow](https://stackoverflow.com/tags/vimeo).

## Want to Contribute?

If you'd like to contribute, please follow our guidelines found in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

`VimeoUpload` is available under the MIT license. See the [LICENSE](LICENSE.md) file for more info.

## Questions?

Tweet at us here: [@vimeoapi](https://twitter.com/vimeoapi).

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`.

Get in touch [here](https://vimeo.com/help/contact).

Interested in working at Vimeo? We're [hiring](https://vimeo.com/jobs)!

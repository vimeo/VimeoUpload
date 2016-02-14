# VimeoUpload

## Contents
* [Getting Started](#getting-started)
      * [Gradle](#gradle)
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

## Getting Started
### Submodule
### CocoaPods
### Initialization
### Authentication

## Uploading Videos
### Starting an Upload
### Canceling an Upload
### Tracking Upload State and Progress
### Additional Configuration

## Want to Contribute?

If you'd like to contribute, please follow our guidelines found in [CONTRIBUTING.md](CONTRIBUTING.md)

## Found an Issue?

Please file any and all issues found in this library to the git [issue tracker](https://github.com/vimeo/vimeoupload/issues)

## Questions?

Tweet at us here: @vimeoapi

Post on [Stackoverflow](http://stackoverflow.com/questions/tagged/vimeo-ios) with the tag `vimeo-ios`

Get in touch [here](https://Vimeo.com/help/contact)

## License

`VimeoUpload` is available under the MIT license. See the [LICENSE](LICENSE) file for more info.


SITUATION

A complex server side API, not ideal for native mobile clients. Four separate requests: create, upload, activate, metadata.

More requests means more failure points. More steps means a process that's challenging to communicate to the user.

We must support iOS 7 and up. Meaning the ALAsset and PHAsset APIs.

Because an upload can take a significant amount of time, we must design for the user backgrounding the application at any point in the process. Therefore all requests must be handled by a background session.

We cannot upload directly from ALAsset and PHAsset source files. So we must export a copy of the asset before starting the upload process. Asset export must happen when the app is in the foreground.

If a PHAsset is in iCloud and not resident on device we need to download it to the device before asset export. Download must happen when the app is in the foreground.

We need to communicate upload progress and state to the user in a variety of locations.  Including communicating state for uploads initiated on other devices / platforms.

We want to be able to conduct concurrent uploads, worst case serial. But we can't use something like the NSOperation API to do so because we'll lose the completion blocks when the app process is terminated.

We need to persist the state of the upload system and each upload to disk so that they live across app launches and terminations.

The app could lose connectivity at any time.
We want to be able to pause and resume the upload system when we lose connectivity. And we want to be able to allow the user to restrict uploads to wifi.

We want the app to be able to crash at arbitrary times and not adversely impact uploads.

Mention quota and account tier considerations?

TARGET

Clear and concise upload system initialization.

Clear and concise upload management and introspection.

An upload system API that accommodate many (all?) UX possibilities.

Collapse the required server-side steps from 4 to 2. (Hopefully 1 at some point).

In the Vimeo iOS app, 2-tap upload UX with a "head start" on each upload.

ACTION

?

RESULT

Diagram

Demo

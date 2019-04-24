fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios build_example
```
fastlane ios build_example
```
buid the example project
### ios run_test
```
fastlane ios run_test
```
run test
### ios ios
```
fastlane ios ios
```
test ios
### ios iosold
```
fastlane ios iosold
```
test ios old
### ios test
```
fastlane ios test
```
test all
### ios version_bump
```
fastlane ios version_bump
```
bumps the project and podspec version

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

workspace 'VimeoUpload'
xcodeproj 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
xcodeproj 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'
xcodeproj 'Examples/VimeoUpload-OSX/VimeoUpload-OSX.xcodeproj'

#install! 'cocoapods', :deterministic_uuids => false # This suppresses the duplicate UUID warnings, introduced in Cocoapods 1.0
# https://github.com/CocoaPods/CocoaPods/issues/4370#issuecomment-183205691

target :'VimeoUpload-iOS' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', :git => 'git@github.com:vimeo/VimeoNetworking.git', :branch => 'master'
    xcodeproj 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
end

target :'VimeoUpload-iOS-OldUpload' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', :git => 'git@github.com:vimeo/VimeoNetworking.git', :branch => 'master'
    xcodeproj 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'
end

target :'VimeoUpload-OSX' do
    platform :osx, '10.9'
    use_frameworks!
    xcodeproj 'Examples/VimeoUpload-OSX/VimeoUpload-OSX.xcodeproj'
end
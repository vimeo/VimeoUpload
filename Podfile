workspace 'VimeoUpload'
xcodeproj 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
xcodeproj 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'
xcodeproj 'Examples/VimeoUpload-OSX/VimeoUpload-OSX.xcodeproj'

def shared_pods
    pod 'AFNetworking', '2.6.3'
end

target :'VimeoUpload-iOS' do
    platform :ios, '8.0'
    #use_frameworks!
    shared_pods
    pod 'VIMNetworking/Model', '6.0.0'
    xcodeproj 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
end

target :'VimeoUpload-iOS-OldUpload' do
    platform :ios, '8.0'
    #use_frameworks!
    shared_pods
    pod 'VIMNetworking/Model', '6.0.0'
    xcodeproj 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'
end

target :'VimeoUpload-OSX' do
    platform :osx, '10.9'
    shared_pods
    xcodeproj 'Examples/VimeoUpload-OSX/VimeoUpload-OSX.xcodeproj'
end
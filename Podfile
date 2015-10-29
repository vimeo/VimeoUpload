workspace 'VimeoUpload'
xcodeproj 'Example/VimeoUpload-iOS-Example/VimeoUpload-iOS-Example.xcodeproj'
xcodeproj 'Example/VimeoUpload-OSX-Example/VimeoUpload-OSX-Example.xcodeproj'

def shared_pods
    pod 'AFNetworking', '2.6.1'
end

target :'VimeoUpload-iOS-Example' do
    platform :ios, '8.0'
    use_frameworks!
    shared_pods
    xcodeproj 'Example/VimeoUpload-iOS-Example/VimeoUpload-iOS-Example.xcodeproj'
end

target :'VimeoUpload-OSX-Example' do
    platform :osx, '10.9'
    shared_pods
    xcodeproj 'Example/VimeoUpload-OSX-Example/VimeoUpload-OSX-Example.xcodeproj'
end
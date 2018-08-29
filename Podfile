workspace 'VimeoUpload'
project 'Framework/VimeoUpload/VimeoUpload.xcodeproj'
project 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
project 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'

target 'VimeoUpload' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', '3.3.0'
    project 'Framework/VimeoUpload/VimeoUpload.xcodeproj'
end

target :'VimeoUpload-iOS' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', '3.3.0'
    project 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'

    target "VimeoUpload-iOSTests" do
        inherit! :search_paths
    end
end

target :'VimeoUpload-iOS-OldUpload' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', '3.3.0'
    project 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'

    target "VimeoUpload-iOS-OldUploadTests" do
        inherit! :search_paths
    end
end

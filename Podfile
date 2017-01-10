workspace 'VimeoUpload'
xcodeproj 'Framework/VimeoUpload/VimeoUpload.xcodeproj'
xcodeproj 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
xcodeproj 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'

target 'VimeoUpload' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', :git => 'git@github.com:vimeo/VimeoNetworking.git', :commit => 'be393b925c3fb523c54b0c59a659e5b3c959858d'
    pod 'AFNetworking', '3.1.0'
    xcodeproj 'Framework/VimeoUpload/VimeoUpload.xcodeproj'
end

target :'VimeoUpload-iOS' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', :git => 'git@github.com:vimeo/VimeoNetworking.git', :commit => 'be393b925c3fb523c54b0c59a659e5b3c959858d'
    xcodeproj 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'
end

target :'VimeoUpload-iOS-OldUpload' do
    platform :ios, '8.0'
    use_frameworks!
    pod 'VimeoNetworking', :git => 'git@github.com:vimeo/VimeoNetworking.git', :commit => 'be393b925c3fb523c54b0c59a659e5b3c959858d'
    xcodeproj 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'
end

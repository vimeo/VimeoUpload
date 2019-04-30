workspace 'VimeoUpload'

use_frameworks!
platform :ios, '8.0'

def shared_pods
    pod 'VimeoNetworking', '4.0.0'
end

target 'VimeoUpload' do
    shared_pods    
    project 'Framework/VimeoUpload/VimeoUpload.xcodeproj'
end

target 'VimeoUpload-iOS' do
    shared_pods
    project 'Examples/VimeoUpload-iOS/VimeoUpload-iOS.xcodeproj'

    target "VimeoUpload-iOSTests" do
        inherit! :search_paths
    end
end

target 'VimeoUpload-iOS-OldUpload' do
    shared_pods
    project 'Examples/VimeoUpload-iOS-OldUpload/VimeoUpload-iOS-OldUpload.xcodeproj'

    target "VimeoUpload-iOS-OldUploadTests" do
        inherit! :search_paths
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|

        target.build_configurations.each do |config|
            other_swift_flags = config.build_settings['OTHER_SWIFT_FLAGS'] || ['$(inherited)']
            other_swift_flags << '-Xfrontend'
            other_swift_flags << '-warn-long-function-bodies=500'

            # Build with Swift 4.2.
            config.build_settings['SWIFT_VERSION'] = '4.2'
        end

    end
end

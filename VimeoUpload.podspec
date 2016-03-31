
Pod::Spec.new do |s|

  s.name         = "VimeoUpload"
  s.version      = "0.0.1"
  s.summary      = "The Vimeo iOS/OSX Upload SDK."
  s.description  = <<-DESC
                            An iOS/OSX library for uploading videos to Vimeo
                   DESC

  s.homepage     = "https://github.com/vimeo/VimeoUpload"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors = { "Alfie Hanssen" => "alfiehanssen@gmail.com",
                "Rob Huebner" => "robh@vimeo.com",
                "Gavin King" => "gavin@vimeo.com"}

  s.social_media_url = "http://twitter.com/vimeo"

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source       = { :git => "https://github.com/vimeo/VimeoUpload.git", :tag => s.version.to_s }
  s.source_files  = "VimeoUpload", "VimeoUpload/**/*.{swift}"

  s.requires_arc = true

  s.ios.frameworks = "Foundation", "AVFoundation", "AssetsLibrary", "Photos", "MobileCoreServices", "UIKit"
  s.osx.frameworks = "Foundation", "AVFoundation", "CoreServices", "Cocoa"
  s.osx.exclude_files = "VimeoUpload/Operations/PHAssetOperation.swift"

  s.subspec 'AFNetworking' do |ss|
    ss.dependency	'AFNetworking', '~> 3.0'
  end

  # s.exclude_files = "Classes/Exclude"

end

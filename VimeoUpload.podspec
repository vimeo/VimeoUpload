
Pod::Spec.new do |s|

  s.name         = "VimeoUpload"
  s.version      = "3.1.0"
  s.summary      = "The Vimeo iOS/OSX Upload SDK."
  s.description  = <<-DESC
                            An iOS/OSX library for uploading videos to Vimeo. The library supports the existing server-side upload flow. It also supports a new private server-side upload flow that will soon be made public. VimeoUpload's core can be extended to support any NSURLSession(background)Task workflow.'
                   DESC

  s.homepage     = "https://github.com/vimeo/VimeoUpload"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors = { "Alfie Hanssen" => "alfie@vimeo.com",
                "Rob Huebner" => "robh@vimeo.com",
                "Gavin King" => "gavin@vimeo.com",
                "Nicole Lehrer" => "nicole@vimeo.com",
                "Chris Larsen" => "chrisl@vimeo.com",
                "Rogerio de Paula Assis" => "rogerio@vimeo.com",
                "Van Le Nguyen" => "van@vimeo.com",
                "Freddy Kellison-Linn" => "freddy.kellisonlinn@vimeo.com",
                "Jason Hawkins" => "jasonh@vimeo.com"
              }

  s.social_media_url = "http://twitter.com/vimeo"

  s.ios.deployment_target = '10.3'

  s.source       = { :git => "https://github.com/vimeo/VimeoUpload.git", :tag => s.version.to_s }
  s.source_files  = "VimeoUpload/**/*.{swift}"
  
  s.requires_arc = true

  s.ios.frameworks = "Foundation", "AVFoundation", "AssetsLibrary", "Photos", "MobileCoreServices", "UIKit", "CoreGraphics"

  s.dependency 'VimeoNetworking'

end

Pod::Spec.new do |s|
  
  s.name        = "MBCaptureCore"
  s.version     = "1.2.3"
  s.summary     = "A delightful Direct API component for document capture"
  s.homepage    = "http://microblink.com"
  s.readme      = "https://raw.githubusercontent.com/BlinkID/capture-ios/v1.2.3/README.md"
  
  s.description = <<-DESC
            The BlinkID Capture iOS SDK gives you the ability to auto-capture high quality images of identity documents in a user-friendly way. The SDK provides you with a rectified image of the document that ensures high success rate in extracting document text or verifying the document validity. 
        DESC
  
  s.license     = { 
        :type => 'commercial',
        :text => <<-LICENSE
                © 2023 Microblink Ltd. All rights reserved.
                LICENSE
        }

  s.authors     = {
        "Microblink" => "info@microblink.com",
        "Jura Skrlec" => "jura.skrlec@microblink.com"
  }

  s.source      = { 
        :http => 'https://github.com/BlinkID/capture-ios/releases/download/v1.2.3/CaptureCore.xcframework.zip'
  }

  s.platform     = :ios

  # ――― MULTI-PLATFORM VALUES ――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = '13.0.0'
  s.ios.vendored_frameworks = 'CaptureCore.xcframework'
  s.ios.libraries = 'c++', 'z'

end

Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '20.0.0'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '11.0'
  s.public_header_files            = 'Stripe/PublicHeaders/Stripe/*.h'
  s.source_files                   = 'Stripe/PublicHeaders/Stripe/*.h', 'Stripe/*.{h,m}'
  s.vendored_libraries             = 'InternalFrameworks/libStripe3DS2.a'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/Resources/**/*.{lproj,json,png,xcassets}' }
  s.ios.resources                  = "Stripe/ExternalResources/Stripe3DS2.bundle"
  s.xcconfig = {
    "OTHER_LDFLAGS" => "$(inherited) -ObjC"
  }
end

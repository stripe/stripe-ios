Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '16.0.7'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "v#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '9.0'
  s.public_header_files            = 'Stripe/PublicHeaders/*.h'
  s.source_files                   = 'Stripe/PublicHeaders/*.h', 'Stripe/*.{h,m}', 'Stripe/Payments/*{h,m}'
  s.vendored_libraries             = 'InternalFrameworks/libStripe3DS2.a'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/Resources/**/*' }
  s.ios.resources                  = "InternalFrameworks/Stripe3DS2.bundle"
  s.xcconfig = { 
    "OTHER_LDFLAGS" => "$(inherited) -ObjC" 
  }
end

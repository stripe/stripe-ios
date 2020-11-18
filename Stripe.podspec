Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '20.1.1'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '11.0'
  s.swift_version		   = '5.0'
  s.source_files                   = 'Stripe/*.swift'
  s.vendored_frameworks            = 'InternalFrameworks/static/Stripe3DS2.xcframework'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/Resources/**/*.{lproj,json,png,xcassets}' }
  s.ios.resources                  = ['InternalFrameworks/static/Stripe3DS2.bundle']
end

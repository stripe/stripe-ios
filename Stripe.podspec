Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '21.4.0'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '11.0'
  s.swift_version		               = '5.0'
  s.source_files                   = 'Stripe/*.swift', 'Stripe/PanModal/**/*.swift'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/Resources/**/*.{lproj,json,png,xcassets}' }
  s.subspec 'Stripe3DS2' do |sp|
    sp.source_files  = 'Stripe3DS2/Stripe3DS2/**/*.{h,m}'
    sp.resource_bundles = { 'Stripe3DS2' => ['Stripe3DS2/Stripe3DS2/Resources/**/*.{lproj,png}'] }
  end
end

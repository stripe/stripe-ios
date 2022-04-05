Pod::Spec.new do |s|
  s.name                           = 'Stripe'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '22.1.0'

  s.summary                        = 'Accept online payments using Stripe.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '12.0'
  s.swift_version		               = '5.0'
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'Stripe/*.swift', 'Stripe/PanModal/**/*.swift'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/Resources/**/*.{lproj,json,png,xcassets}' }
  s.dependency                       'StripeCore', "#{s.version}"
  s.dependency                       'StripeUICore', "#{s.version}"
  s.dependency                       'StripeApplePay', "#{s.version}"
  s.subspec 'Stripe3DS2' do |sp|
    sp.source_files  = 'Stripe3DS2/Stripe3DS2/**/*.{h,m}'
    sp.resource_bundles = { 'Stripe3DS2' => ['Stripe3DS2/Stripe3DS2/Resources/**/*.{lproj,png}'] }
  end
end

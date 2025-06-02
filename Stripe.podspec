Pod::Spec.new do |s|
  s.name                           = 'Stripe'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.14.0'

  s.summary                        = 'Accept online payments using Stripe.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.requires_arc                   = true
  s.swift_version                  = '5.0'
  s.weak_framework                 = 'SwiftUI'
  
  # Platform configurations
  s.ios.deployment_target          = '13.0'
  s.osx.deployment_target          = '11.0'
  
  # iOS specific frameworks
  s.ios.frameworks                 = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation', 'UIKit'
  
  # macOS specific frameworks
  s.osx.frameworks                 = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation', 'AppKit'
  
  s.source_files                   = 'Stripe/StripeiOS/Source/*.swift'
  s.ios.resource_bundle            = { 'StripeBundle' => ['Stripe/StripeiOS/Resources/**/*.{lproj,png,xcassets}', 'Stripe/StripeiOS/PrivacyInfo.xcprivacy'] }
  s.osx.resource_bundle            = { 'StripeBundle' => ['Stripe/StripeiOS/Resources/**/*.{lproj,png,xcassets}', 'Stripe/StripeiOS/PrivacyInfo.xcprivacy'] }
  s.dependency                       'StripeCore', s.version.to_s
  s.dependency                       'StripeUICore', s.version.to_s
  s.dependency                       'StripeApplePay', s.version.to_s
  s.dependency                       'StripePayments', s.version.to_s
  s.dependency                       'StripePaymentsUI', s.version.to_s
end

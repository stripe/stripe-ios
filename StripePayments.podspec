Pod::Spec.new do |s|
  s.name                           = 'StripePayments'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.14.0'

  s.summary                        = 'Stripe SDK for iOS & macOS'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.requires_arc                   = true
  s.swift_version                  = '5.0'
  
  # Platform configurations
  s.ios.deployment_target          = '13.0'
  s.osx.deployment_target          = '11.0'
  
  # iOS specific frameworks
  s.ios.frameworks                 = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation', 'UIKit'
  
  # macOS specific frameworks
  s.osx.frameworks                 = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation', 'AppKit'
  
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'StripePayments/StripePayments/**/*.swift'
  s.ios.resource_bundle            = { 'StripePayments' => ['StripePayments/StripePayments/Resources/**/*.lproj', 'StripePayments/StripePayments/Resources/**/*.{png,json}'] }
  s.osx.resource_bundle            = { 'StripePayments' => ['StripePayments/StripePayments/Resources/**/*.lproj', 'StripePayments/StripePayments/Resources/**/*.{png,json}'] }
  s.dependency                       'StripeCore', "#{s.version}"
  s.dependency                       'Stripe3DS2', '2.7.4'
end

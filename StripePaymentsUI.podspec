Pod::Spec.new do |s|
  s.name                           = 'StripePaymentsUI'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.14.0'

  s.summary                        = 'Stripe SDK for iOS & macOS UI Components'
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
  s.ios.frameworks                 = 'Foundation', 'UIKit'
  
  # macOS specific frameworks
  s.osx.frameworks                 = 'Foundation', 'AppKit'
  
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'StripePaymentsUI/StripePaymentsUI/**/*.swift'
  s.ios.resource_bundle            = { 'StripePaymentsUIBundle' => ['StripePaymentsUI/StripePaymentsUI/Resources/**/*.{xcassets,lproj}', 'StripePaymentsUI/StripePaymentsUI/Resources/**/*.{png,json}'] }
  s.osx.resource_bundle            = { 'StripePaymentsUIBundle' => ['StripePaymentsUI/StripePaymentsUI/Resources/**/*.{xcassets,lproj}', 'StripePaymentsUI/StripePaymentsUI/Resources/**/*.{png,json}'] }
  s.dependency                       'StripeCore', "#{s.version}"
  s.dependency                       'StripeUICore', "#{s.version}"
  s.dependency                       'StripePayments', "#{s.version}"
  s.dependency                       'Stripe3DS2', '2.7.4'
end

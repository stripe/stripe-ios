Pod::Spec.new do |s|
  s.name                           = 'Stripe'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '23.4.0'

  s.summary                        = 'Accept online payments using Stripe.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.swift_version		               = '5.0'
  s.ios.deployment_target          = '13.0'
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'Stripe/StripeiOS/Source/*.swift'
  s.ios.resource_bundle            = { 'Stripe' => 'Stripe/StripeiOS/Resources/**/*.{lproj,png}' }
  s.dependency                       'StripeCore', s.version.to_s
  s.dependency                       'StripeUICore', s.version.to_s
  s.dependency                       'StripeApplePay', s.version.to_s
  s.dependency                       'StripePayments', s.version.to_s
  s.dependency                       'StripePaymentsUI', s.version.to_s
end

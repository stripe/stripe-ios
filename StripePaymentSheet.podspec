Pod::Spec.new do |s|
  s.name                           = 'StripePaymentSheet'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '23.17.2'

  s.summary                        = "Stripe's prebuilt payment UI."
  s.license                        = { type: 'MIT', file: 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { git: 'https://github.com/stripe/stripe-ios.git', tag: s.version.to_s }
  s.frameworks                     = 'Foundation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '13.0'
  s.swift_version = '5.0'
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'StripePaymentSheet/StripePaymentSheet/Source/**/*.swift'
  s.ios.resource_bundle            = { 'StripePaymentSheet' => 'StripePaymentSheet/StripePaymentSheet/Resources/**/*.{lproj,png,xcassets,json}' }
  s.dependency                       'StripeCore', s.version.to_s
  s.dependency                       'StripePayments', s.version.to_s
  s.dependency                       'StripePaymentsUI', s.version.to_s
  s.dependency                       'StripeApplePay', s.version.to_s
end

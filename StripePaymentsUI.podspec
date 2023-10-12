Pod::Spec.new do |s|
  s.name                           = 'StripePaymentsUI'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '23.17.1'

  s.summary                        = 'UI elements and API bindings for building a custom payment flow using Stripe.'
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
  s.source_files                   = 'StripePaymentsUI/StripePaymentsUI/Source/**/*.swift'
  s.ios.resource_bundle            = { 'StripePaymentsUI' => 'StripePaymentsUI/StripePaymentsUI/Resources/**/*.{lproj,png,json}' }
  s.dependency                       'StripeCore', s.version.to_s
  s.dependency                       'StripeUICore', s.version.to_s
  s.dependency                       'StripePayments', s.version.to_s
end

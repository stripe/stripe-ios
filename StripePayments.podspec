Pod::Spec.new do |s|
  s.name                           = 'StripePayments'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '23.4.0'

  s.summary                        = 'Bindings for the Stripe Payments API.'
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
  s.source_files                   = 'StripePayments/StripePayments/Source/**/*.swift'
  s.ios.resource_bundle            = { 'StripePayments' => 'StripePayments/StripePayments/Resources/**/*.{lproj}' }
  s.dependency                       'StripeCore', s.version.to_s
  s.subspec 'Stripe3DS2' do |sp|
    sp.source_files = 'Stripe3DS2/Stripe3DS2/**/*.{h,m}'
    sp.resource_bundles = { 'Stripe3DS2' => ['Stripe3DS2/Stripe3DS2/Resources/**/*.{lproj,png}'] }
  end
end

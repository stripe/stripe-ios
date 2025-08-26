Pod::Spec.new do |s|
  s.name                           = 'StripeCryptoOnramp'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.21.1'

  s.summary                        = 'Facilitates crypto onramp transactions with built-in KYC and identity verification.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/crypto'
  s.readme                         = 'StripeCryptoOnramp/README.md'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'UIKit', 'PassKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '13.0'
  s.swift_version                  = '5.0'
  s.source_files                   = 'StripeCryptoOnramp/StripeCryptoOnramp/**/*.swift'
  s.ios.resource_bundle            = { 'StripeCryptoOnrampBundle' => 'StripeCryptoOnramp/StripeCryptoOnramp/Resources/**/*.{lproj,json,png,xcassets}' }
  s.dependency                     'StripeCore', "#{s.version}"
  s.dependency                     'StripeUICore', "#{s.version}"
  s.dependency                     'StripeApplePay', "#{s.version}"
  s.dependency                     'StripePayments', "#{s.version}"
  s.dependency                     'StripePaymentsUI', "#{s.version}"
  s.dependency                     'StripePaymentSheet', "#{s.version}"
  s.dependency                     'StripeIdentity', "#{s.version}"
end

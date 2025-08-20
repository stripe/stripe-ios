Pod::Spec.new do |s|
  s.name                           = 'StripeCryptoOnramp'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.16.2'

  s.summary                        = 'StripeCryptoOnramp provides the ability to sign up/in a Link user with custom UI provided by the client.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.readme                         = 'StripeCryptoOnramp/README.md'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '13.0'
  s.swift_version                  = '5.0'
  s.source_files                   = 'StripeCryptoOnramp/StripeCryptoOnramp/**/*.swift'
  s.dependency                     'StripeCore', "#{s.version}"
end

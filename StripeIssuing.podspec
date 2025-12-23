Pod::Spec.new do |s|
  s.name                           = 'StripeIssuing'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '25.3.1'

  s.summary                        = 'Use to setup ios integration for Issuing Token Push Provision'
  s.license                        = { type: 'MIT', file: 'LICENSE' }
  s.homepage                       = 'https://docs.stripe.com/issuing/cards/digital-wallets#push-provisioning'
  s.readme                         = 'StripeIssuing/README.md'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { git: 'https://github.com/stripe/stripe-ios.git', tag: "#{s.version}" }
  s.frameworks                     = 'Foundation', 'WebKit', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.swift_version                  = '5.0'
  s.ios.deployment_target          = '13.0'
  s.source_files                   = 'StripeIssuing/StripeIssuing/**/*.swift'
end

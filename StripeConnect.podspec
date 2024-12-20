Pod::Spec.new do |s|
  s.name                           = 'StripeConnect'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.2.0'

  s.summary                        = 'Use Connect embedded components to add connected account dashboard functionality to your app.'
  s.license                        = { type: 'MIT', file: 'LICENSE' }
  s.homepage                       = 'https://docs.stripe.com/connect/get-started-connect-embedded-components'
  s.readme                         = 'StripeConnect/README.md'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { git: 'https://github.com/stripe/stripe-ios.git', tag: "#{s.version}" }
  s.frameworks                     = 'Foundation', 'WebKit', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.swift_version = '5.0'
  # Connect only supports 15+, but setting this to 13.0 to make installation tests easier.
  s.ios.deployment_target          = '13.0'
  s.source_files                   = 'StripeConnect/StripeConnect/**/*.swift'
  s.dependency                       'StripeCore', s.version.to_s
  s.dependency                       'StripeUICore', s.version.to_s
  s.dependency                       'StripeFinancialConnections', s.version.to_s
end

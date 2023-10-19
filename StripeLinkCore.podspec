Pod::Spec.new do |s|
  s.name                           = 'StripeLinkCore'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '23.17.2'

  s.summary                        = 'StripeLinkCore contains shared infrastructure used by all Stripe pods. '\
                                     'It is not meant to be used without other Stripe pods.'
  s.license                        = { type: 'MIT', file: 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { git: 'https://github.com/stripe/stripe-ios.git', tag: s.version.to_s }
  s.frameworks                     = 'Foundation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '13.0'
  s.swift_version                  = '5.0'
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'StripeLinkCore/StripeLinkCore/**/*.swift'
  # s.dependency                       'StripeCore', s.version.to_s
end

Pod::Spec.new do |s|
  s.name                           = 'StripeCore'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '21.6.0'

  s.summary                        = 'StripeCore contains shared infrastructure used by all Stripe pods. '\
                                     'It is not meant to be used without other Stripe pods.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  # TODO(mludowise|MOBILESDK-265): Temporarily publish to branch so `pod lib lint` can pass.
  # Change from branch back to `:tag => "#{s.version}"` before next deploy.
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :branch => "StripeCore-#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '11.0'
  s.swift_version		               = '5.0'
  s.source_files                   = 'StripeCore/StripeCore/**/*.swift'
end

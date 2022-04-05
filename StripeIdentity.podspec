Pod::Spec.new do |s|
  s.name                           = 'StripeIdentity'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '22.1.0'

  s.summary                        = 'Securely capture ID documents and selfies on iOS for use with Stripe\'s Identity API to confirm the identity of global users.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/identity'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'WebKit', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '12.0'
  s.swift_version		               = '5.0'
  s.weak_framework = 'SwiftUI'
  s.source_files                   = 'StripeIdentity/StripeIdentity/**/*.swift'
  s.ios.resource_bundle            = { 'StripeIdentity' => 'StripeIdentity/StripeIdentity/Resources/**/*.{lproj,json,png,xcassets}' }
  s.dependency                       'StripeCore', "#{s.version}"
  s.dependency                       'StripeUICore', "#{s.version}"
  s.dependency                       'StripeCameraCore', "#{s.version}"
end

Pod::Spec.new do |s|
  s.name                           = 'StripeUICore'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '22.1.0'

  s.summary                        = 'StripeUICore contains shared infrastructure used by all Stripe pods. '\
                                     'It is not meant to be used without other Stripe pods.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '12.0'
  s.swift_version		               = '5.0'
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'StripeUICore/StripeUICore/**/*.swift'
  s.ios.resource_bundle            = { 'StripeUICore' => 'StripeUICore/StripeUICore/Resources/**/*.{lproj,png,xcassets,json}' }
  s.dependency                       'StripeCore', "#{s.version}"
end

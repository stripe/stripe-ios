Pod::Spec.new do |s|
  s.name                           = 'StripeCore'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '24.14.0'

  s.summary                        = 'StripeCore contains shared infrastructure used by all Stripe pods. '\
                                     'It is not meant to be used without other Stripe pods.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.requires_arc                   = true
  s.swift_version                  = '5.0'
  
  # Platform configurations
  s.ios.deployment_target          = '13.0'
  s.osx.deployment_target          = '11.0'
  
  # iOS specific frameworks
  s.ios.frameworks                 = 'Foundation', 'UIKit'
  
  # macOS specific frameworks
  s.osx.frameworks                 = 'Foundation', 'AppKit'
  
  s.source_files                   = 'StripeCore/StripeCore/**/*.swift'
  s.ios.resource_bundle            = { 'StripeCoreBundle' => ['StripeCore/StripeCore/Resources/**/*.lproj', 'StripeCore/StripeCore/PrivacyInfo.xcprivacy'] }
  s.osx.resource_bundle            = { 'StripeCoreBundle' => ['StripeCore/StripeCore/Resources/**/*.lproj', 'StripeCore/StripeCore/PrivacyInfo.xcprivacy'] }
end

Pod::Spec.new do |s|
  s.name                           = 'StripeScan'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '21.9.0'

  s.summary                        = 'Scan credit and debit cards to verify that they\'re genuine'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '11.0'
  s.swift_version		   = '5.0'
  s.weak_framework                 = 'AVKit', 'CoreML', 'VideoToolbox', 'Vision', 'AVFoundation'
  s.source_files                   = 'StripeScan/StripeScan/**/*.{swift,mlmodel,mlmodelc}'
end

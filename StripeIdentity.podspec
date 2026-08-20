Pod::Spec.new do |s|
  s.name                           = 'StripeIdentity'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '26.7.0'

  s.summary                        = 'Securely capture ID documents and selfies on iOS for use with Stripe\'s Identity API to confirm the identity of global users.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/identity'
  s.readme                         = 'StripeIdentity/README.md'
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = [
    'Accelerate',
    'AVFoundation',
    'CoreMedia',
    'CoreVideo',
    'Foundation',
    'UIKit',
    'WebKit',
  ]
  s.libraries                      = 'c++', 'z'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '15.0'
  s.swift_version		               = '5.0'
  s.weak_framework = 'SwiftUI'
  s.source_files                   = [
    'StripeIdentity/StripeIdentity/**/*.swift',
    'LocalPackages/MediaPipeSPM/Sources/MediaPipeSPMGraphReferences/**/*.{c,h}',
  ]
  s.private_header_files           = [
    'LocalPackages/MediaPipeSPM/Sources/MediaPipeSPMGraphReferences/**/*.h',
  ]
  s.pod_target_xcconfig            = { 'OTHER_LDFLAGS' => '$(inherited) -ObjC' }
  s.vendored_frameworks            = [
    'LocalPackages/MediaPipeSPM/Artifacts/MediaPipeCommonGraphLibraries.xcframework',
    'LocalPackages/MediaPipeSPM/Artifacts/MediaPipeTasksCommon.xcframework',
    'LocalPackages/MediaPipeSPM/Artifacts/MediaPipeTasksVision.xcframework',
  ]
  s.ios.resource_bundle            = { 'StripeIdentityBundle' => 'StripeIdentity/StripeIdentity/Resources/**/*.{lproj,json,png,wav,xcassets,task}' }
  s.preserve_paths                 = 'NOTICE', 'LocalPackages/MediaPipeSPM/LICENSE-MediaPipe'
  s.dependency                       'StripeCore', "#{s.version}"
  s.dependency                       'StripeUICore', "#{s.version}"
  s.dependency                       'StripeCameraCore', "#{s.version}"
end

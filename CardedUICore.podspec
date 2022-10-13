Pod::Spec.new do |s|
  s.name                           = 'CardedUICore'

  # Do not update s.version directly.
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
  s.version                        = '22.8.4'

  s.summary                        = 'CardedUICore contains shared infrastructure used by all Carded pods. '\
                                     'It is not meant to be used without other Carded pods.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://carded.org/docs/mobile/ios'
  s.authors                        = { 'Carded' => 'support+github@cardez.org' }
  s.source                         = { :git => 'https://github.com/carded/carded-ios.git', :tag => "#{s.version}" }
  s.frameworks                     = 'Foundation', 'UIKit'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '12.0'
  s.swift_version		               = '5.0'
  s.weak_framework                 = 'SwiftUI'
  s.source_files                   = 'CardedUICore/CardedUICore/**/*.swift'
  s.ios.resource_bundle            = { 'CardedUICore' => 'CardedUICore/CardedUICore/Resources/**/*.{lproj,png,json}' }
  s.dependency                       'CardedCore', "#{s.version}"
end

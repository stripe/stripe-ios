Pod::Spec.new do |s| 
  s.name                           = 'StripeApplePay' 

  # Do not update s.version directly. 
  # Instead, update the VERSION file and run ./ci_scripts/update_version.sh 
  s.version                        = '22.1.0' 

  s.summary                        = 'StripeApplePay is a lightweight Apple Pay SDK intended for building App Clips '\
                                     'or other size-constrained apps.' 
  s.license                        = { :type => 'MIT', :file => 'LICENSE' } 
  s.homepage                       = 'https://stripe.com/docs/apple-pay' 
  s.authors                        = { 'Stripe' => 'support+github@stripe.com' } 
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" } 
  s.frameworks                     = 'Foundation', 'Security', 'WebKit', 'PassKit', 'Contacts', 'CoreLocation' 
  s.requires_arc                   = true 
  s.platform                       = :ios 
  s.ios.deployment_target          = '12.0' 
  s.swift_version                  = '5.0' 
  s.source_files                   = 'StripeApplePay/StripeApplePay/**/*.swift' 
  s.dependency                       'StripeCore', "#{s.version}"
end 

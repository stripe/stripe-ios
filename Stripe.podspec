Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '8.0.4'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Jack Flintermann' => 'jack@stripe.com', 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "v#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security'
  s.weak_frameworks                = 'PassKit', 'AddressBook'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.ios.deployment_target          = '7.0'
  s.public_header_files            = 'Stripe/PublicHeaders/*.h'
  s.source_files                   = 'Stripe/PublicHeaders/*.h', 'Stripe/*.{h,m}'
  s.resources                      = 'Stripe/Resources/**/*'
end

Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '7.0.1'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Jack Flintermann' => 'jack@stripe.com', 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "v#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security'
  s.weak_frameworks                = 'PassKit', 'AddressBook'
  s.requires_arc                   = true
  s.platform                       = :ios
  s.deployment_target              = '7.0'
  s.default_subspecs               = 'Core'

  s.subspec 'Core' do |ss|
    ss.public_header_files         = 'Stripe/PublicHeaders/*.h'
    ss.source_files                = 'Stripe/PublicHeaders/*.h', 'Stripe/*.{h,m}', 'Stripe/**/*.{h,m}'
    ss.resources                   = 'Stripe/Resources/**/*'
  end

  s.subspec 'Checkout' do |ss|
    # This has been merged with the core subspec and is now empty; it's still around to avoid breaking legacy Podfiles.
    ss.dependency 'Stripe/Core'
  end

  s.subspec 'ApplePay' do |ss|
    # This has been merged with the core subspec and is now empty; it's still around to avoid breaking legacy Podfiles.
    ss.dependency 'Stripe/Core'
  end
end

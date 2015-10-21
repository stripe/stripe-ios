Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '6.0.1'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Jack Flintermann' => 'jack@stripe.com', 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "v#{s.version}" }
  s.ios.frameworks                 = 'Foundation', 'Security'
  s.ios.weak_frameworks            = 'PassKit', 'AddressBook'
  s.osx.frameworks                 = 'Foundation', 'Security', 'WebKit'
  s.requires_arc                   = true
  s.ios.deployment_target          = '6.0'
  s.osx.deployment_target          = '10.9'
  s.default_subspecs               = 'Core'

  s.subspec 'Core' do |ss|
    ss.public_header_files         = 'Stripe/PublicHeaders/*.h', 'Stripe/PublicHeaders/Checkout/*.h'
    ss.ios.public_header_files     = 'Stripe/PublicHeaders/ApplePay/*.h', 'Stripe/PublicHeaders/UI/*.h'
    ss.source_files                = 'Stripe/PublicHeaders/*.h', 'Stripe/*.{h,m}', 'Stripe/PublicHeaders/Checkout/*.h', 'Stripe/Checkout/*.{h,m}'
    ss.ios.source_files            = 'Stripe/PublicHeaders/ApplePay/*.h', 'Stripe/ApplePay/*.{h,m}', 'Stripe/PublicHeaders/UI/*.h', 'Stripe/UI/*.{h,m}', 'Stripe/Fabric/*'
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

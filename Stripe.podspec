Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = '3.1.0'
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Jack Flintermann' => 'jack@stripe.com', 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "v#{s.version}" }
  s.ios.frameworks                 = 'Foundation', 'Security'
  s.osx.frameworks                 = 'Foundation', 'Security', 'WebKit'
  s.requires_arc                   = true
  s.ios.deployment_target          = '6.0'
  s.osx.deployment_target          = '10.9'
  s.default_subspecs               = 'Core', 'Checkout'

  s.subspec 'Core' do |subspec|
    subspec.public_header_files    = 'Stripe/PublicHeaders/*.h'
    subspec.source_files           = 'Stripe/PublicHeaders/*.h', 'Stripe/*.{h,m}'
  end

  s.subspec 'Checkout' do |subspec|
    subspec.dependency               'Stripe/Core'
    subspec.public_header_files    = 'Stripe/PublicHeaders/Checkout/*.h'
    subspec.source_files           = 'Stripe/PublicHeaders/Checkout/*.h', 'Stripe/Checkout/*.{h,m}'
  end

  s.subspec 'ApplePay' do |subspec|
    subspec.platform                = :ios
    subspec.dependency                'Stripe/Core'
    subspec.ios.public_header_files = 'Stripe/PublicHeaders/ApplePay/*.h'
    subspec.ios.source_files        = 'Stripe/PublicHeaders/ApplePay/*.h', 'Stripe/ApplePay/*.{h,m}'
    subspec.ios.weak_frameworks     = 'PassKit', 'AddressBook'
  end
end

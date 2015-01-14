Pod::Spec.new do |s|
  s.name                           = 'Stripe'
  s.version                        = File.open('VERSION').first.strip
  s.summary                        = 'Stripe is a web-based API for accepting payments online.'
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = 'https://stripe.com/docs/mobile/ios'
  s.authors                        = { 'Jack Flintermann' => 'jack@stripe.com', 'Stripe' => 'support+github@stripe.com' }
  s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "v#{s.version}" }
  s.frameworks                     = 'Foundation', 'Security'
  s.requires_arc                   = true
  s.ios.deployment_target          = '6.0'
  s.osx.deployment_target          = '10.10'
  s.default_subspecs               = 'Core', 'Checkout'

  s.subspec 'Core' do |subspec|
    subspec.source_files           = 'Stripe/**.{h,m}'
    subspec.public_header_files    = 'Stripe/PublicHeaders/*.h'
    subspec.exclude_files          = 'Stripe/ApplePay/*', 'Stripe/PublicHeaders/ApplePay/*'
  end

  s.subspec 'Card' do |subspec|
    subspec.source_files           = 'Stripe/PublicHeaders/STPCard.h', 'Stripe/STPCard.m', 'Stripe/PublicHeaders/StripeError.h', 'Stripe/StripeError.m'
  end

  s.subspec 'Checkout' do |subspec|
    subspec.dependency               'Stripe/Core'
    subspec.source_files           = 'Stripe/Checkout/*.{h,m}'
    subspec.public_header_files    = 'Stripe/PublicHeaders/Checkout/*.h'
    subspec.osx.frameworks         = 'WebKit'
  end

  s.subspec 'ApplePay' do |subspec|
    subspec.platform                = :ios
    subspec.dependency                'Stripe/Core'
    subspec.dependency                'Stripe/Checkout'
    subspec.ios.source_files        = 'Stripe/ApplePay/*.{h,m}'
    subspec.ios.public_header_files = 'Stripe/PublicHeaders/ApplePay/*.h'
    subspec.ios.weak_frameworks     = 'PassKit', 'AddressBook'
  end
end

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
  s.default_subspecs               = 'Core'

  s.subspec 'Core' do |subspec|
    subspec.source_files           = 'Stripe/**.{h,m}'
    subspec.public_header_files    = 'Stripe/PublicHeaders/*.h', 'Stripe/PublicHeaders/Checkout/*.h'
    subspec.exclude_files          = 'Stripe/ApplePay/*', 'Stripe/PublicHeaders/ApplePay/*'
  end

  s.subspec 'ApplePay' do |subspec|
    subspec.platform                = :ios
    subspec.dependency                'Stripe/Core'
    subspec.ios.source_files        = 'Stripe/ApplePay/*.{h,m}'
    subspec.ios.public_header_files = 'Stripe/PublicHeaders/ApplePay/*.h'
    subspec.ios.weak_frameworks     = 'PassKit', 'AddressBook'
  end
end

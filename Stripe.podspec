Pod::Spec.new do |s|
  s.name                           = "Stripe"
  s.version                        = "2.2.2"
  s.summary                        = "Stripe is a web-based API for accepting payments online."
  s.license                        = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage                       = "https://stripe.com"
  s.author                         = { "Jack Flintermann" => "jack@stripe.com" }
  s.source                         = { :git => "https://github.com/stripe/stripe-ios.git", :tag => "v#{s.version}" }
  s.platform                       = :ios
  s.frameworks                     = 'Foundation', 'Security'
  s.requires_arc                   = true
  s.ios.deployment_target          = '5.0'
  s.default_subspec                = 'Core'

  s.subspec "Core" do |subspec|
    subspec.source_files           = 'Stripe/*.{h,m}'
    subspec.public_header_files    = 'Stripe/*.h'
    subspec.exclude_files          = 'Stripe/ApplePay/*'
  end

  s.subspec "Card" do |subspec|
    subspec.source_files           = 'Stripe/STPCard.h', 'Stripe/STPCard.m', 'Stripe/STPFormEncodeProtocol.h', 'Stripe/StripeError.h', 'Stripe/StripeError.m', 'Stripe/STPUtils.h', 'Stripe/STPUtils.m'
  end

  s.subspec "ApplePay" do |subspec|
    subspec.dependency               "Stripe/Core"
    subspec.source_files           = 'Stripe/ApplePay/*'
    subspec.prefix_header_contents = "#define STRIPE_ENABLE_APPLEPAY YES"
    subspec.weak_frameworks        = 'PassKit', 'AddressBook'
  end
end

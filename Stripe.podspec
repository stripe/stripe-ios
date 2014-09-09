Pod::Spec.new do |s|
  s.name                  = "Stripe"
  s.version               = "2.0"
  s.summary               = "Stripe is a web-based API for accepting payments online."
  s.license               = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage              = "https://stripe.com"
  s.author                = { "Jack Flintermann" => "jack@stripe.com" }
  s.source                = { :git => "https://github.com/stripe/stripe-ios.git", :tag => "v2.0"}
  s.source_files          = 'Stripe/*.{h,m}'
  s.public_header_files   = 'Stripe/*.h'
  s.platform              = :ios
  s.frameworks            = 'Foundation', 'Security', 'PassKit'
  s.requires_arc          = true
  s.ios.deployment_target = '5.0'
end

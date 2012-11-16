Pod::Spec.new do |s|
  s.name                = "Stripe"
  s.version             = "1.0.0"
  s.summary             = "Stripe is a web-based API for accepting payments online."
  s.license             = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage            = "https://stripe.com"
  s.author              = { "Saikat Chakrabarti" => "saikat@stripe.com" }
  s.source              = { :git => "https://github.com/stripe/stripe-ios.git", :commit => "master"}
  s.source_files        = 'src/*.{h,m}'
  s.public_header_files = 'src/*.h'
  s.framework           = 'Foundation'
end

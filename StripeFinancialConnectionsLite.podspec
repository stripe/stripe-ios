Pod::Spec.new do |s|
    s.name                           = 'StripeFinancialConnectionsLite'
  
    # Do not update s.version directly.
    # Instead, update the VERSION file and run ./ci_scripts/update_version.sh
    s.version                        = '24.16.1'
  
    s.summary                        = 'A lightweight implementation of Stripe Financial Connections for iOS.'
    s.license                        = { :type => 'MIT', :file => 'LICENSE' }
    s.homepage                       = 'https://stripe.com/docs/mobile/ios'
    s.readme                         = 'StripeFinancialConnectionsLite/README.md'
    s.authors                        = { 'Stripe' => 'support+github@stripe.com' }
    s.source                         = { :git => 'https://github.com/stripe/stripe-ios.git', :tag => "#{s.version}" }
    s.frameworks                     = 'Foundation', 'UIKit', 'WebKit', 'AuthenticationServices'
    s.requires_arc                   = true
    s.platform                       = :ios
    s.ios.deployment_target          = '13.0'
    s.swift_version                  = '5.0'
    s.source_files                   = 'StripeFinancialConnectionsLite/StripeFinancialConnectionsLite/**/*.swift'
    s.dependency                     'StripeCore', "#{s.version}"
  end
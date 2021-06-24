#!/usr/bin/env ruby

puts "Checking that version is set correctly..."
file_version = File.open('VERSION').first.strip

swift_search_result = `grep #{file_version} ./Stripe/StripeAPIConfiguration+Version.swift`
if swift_search_result.length == 0
  abort("VERSION does not match STPSDKVersion in StripeAPIConfiguration+Version.swift")
end

xcconfig_search_result = `grep #{file_version} ./Stripe/BuildConfigurations/Version.xcconfig`

if xcconfig_search_result.length == 0
  abort("VERSION does not match Version.xcconfig")
end


podspec_search_result = `grep #{file_version} ./Stripe.podspec`

if podspec_search_result.length == 0
  abort("VERSION does not match s.version in Stripe.podspec")
end

puts "Done!"

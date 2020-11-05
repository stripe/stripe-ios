#!/usr/bin/env ruby

puts "Checking that version is set correctly..."
file_version = File.open('VERSION').first.strip
search_result = `grep #{file_version} ./Stripe/STPAPIClient.swift`

if search_result.length == 0
  abort("VERSION does not match STPSDKVersion in STPAPIClient.swift")
end

puts "Done!"

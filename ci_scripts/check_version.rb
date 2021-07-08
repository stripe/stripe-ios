#!/usr/bin/env ruby

def fail_check (message)
  abort("#{message}\nRun `./ci_scripts/update_version.sh`")
end

puts "Checking that version is set correctly..."
file_version = File.open('VERSION').first.strip

swift_search_result = `grep #{file_version} "./StripeCore/StripeCore/Source/API Bindings/StripeAPIConfiguration+Version.swift"`
if swift_search_result.length == 0
  fail_check("VERSION does not match STPSDKVersion in StripeAPIConfiguration+Version.swift")
end

xcconfig_search_result = `grep #{file_version} ./BuildConfigurations/Version.xcconfig`

if xcconfig_search_result.length == 0
  fail_check("VERSION does not match Version.xcconfig")
end


Dir.glob('./*.podspec') do |podspec|

  podspec_search_result = `grep #{file_version} #{podspec}`

  if podspec_search_result.length == 0
    fail_check("VERSION does not match s.version in #{File.basename(podspec)}")
  end
end

puts "Done!"

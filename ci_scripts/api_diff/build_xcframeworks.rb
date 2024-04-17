#!/usr/bin/env ruby
require 'open3'
require_relative 'get_frameworks'

# function to checkout git branch, build and generate API JSON
def checkout_build_generate(branch, archive_name)
  # Checkout old or new version, build and generate API JSON
  puts "Building and generating public interface from #{branch}..."
  system("git checkout #{branch}")

  system("xcodebuild clean archive \
  -quiet \
  -workspace 'Stripe.xcworkspace' \
  -scheme 'AllStripeFrameworks' \
  -destination 'generic/platform=iOS Simulator' \
  -configuration 'Release' \
  -archivePath './StripeFrameworks-sim-#{archive_name}.xcarchive' \
  -sdk iphonesimulator \
  SUPPORTS_MACCATALYST=NO \
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE \
  SKIP_INSTALL=NO")

  for framework_name in GetFrameworks.framework_names("./modules.yaml")
    system("xcodebuild -create-xcframework \
        -framework './StripeFrameworks-sim-#{archive_name}.xcarchive/Products/Library/Frameworks/#{framework_name}.framework' \
        -output './#{framework_name}-#{archive_name}.xcframework'")
  end

end

# Run function for master and head_ref
checkout_build_generate("master", "master")
checkout_build_generate(ENV['GITHUB_HEAD_REF'], "new")
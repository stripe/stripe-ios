#!/usr/bin/env ruby
require 'open3'

# function to checkout git branch, build and generate API JSON
def checkout_build_generate(branch, archive_name)
  # Checkout old or new version, build and generate API JSON
  puts "Building and generating public interface from #{branch}..."
  system("git checkout #{branch}")

#   system("xcodebuild clean archive \
#   -quiet \
#   -workspace 'Stripe.xcworkspace' \
#   -scheme 'AllStripeFrameworks' \
#   -destination 'generic/platform=iOS Simulator' \
#   -configuration 'Release' \
#   -archivePath './StripeFrameworks-sim-#{archive_name}.xcarchive' \
#   -sdk iphonesimulator \
#   SUPPORTS_MACCATALYST=NO \
#   BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
#   SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE \
#   SKIP_INSTALL=NO")

  Zip::File.open(File.join_if_safe(build_dir, 'Stripe.xcframework.zip'), create: true) do |zipfile|
    # Add module framework directories to zip
    modules.each do |m|
      framework_name = m['framework_name']
      Dir.glob("#{build_dir}/#{framework_name}.xcframework/**/*").each do |file|
        file_name = Pathname.new(file).relative_path_from(Pathname.new(build_dir))
        system("xcodebuild -create-xcframework \
        -framework './StripeFrameworks-sim-#{archive_name}.xcarchive/Products/Library/Frameworks/StripePaymentSheet.framework' \
        -output './StripePaymentSheet-#{archive_name}.xcframework'")
      end
    end
  end
end

# Run function for master and head_ref
# checkout_build_generate("master", "master")
checkout_build_generate(ENV['GITHUB_HEAD_REF'], "new")
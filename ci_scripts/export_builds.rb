#!/usr/bin/env ruby

require 'fileutils'
require 'zip'
require 'yaml'

# MARK: - Helpers

def info(string)
  puts "[#{File.basename(__FILE__)}] [INFO] #{string}"
end

def die(string)
  abort "[#{File.basename(__FILE__)}] [ERROR] #{string}"
end

# Joins the given strings. If one or more arguments is nil or empty, an exception is raised.
def File.join_if_safe(arg1, *otherArgs)
  args = [arg1] + otherArgs

  # Check for empty or nil strings
  args.each do |arg|
    raise 'Cannot join nil or empty string.' if arg.nil? || arg.empty?
  end

  File.join(args)
end

# MARK: - Main

script_dir = __dir__
root_dir = File.expand_path(File.join_if_safe(script_dir, '..'), Dir.getwd)
modules = YAML.load_file('modules.yaml')['modules']

# Package up 3DS2 too
modules.append({ 'scheme' => 'Stripe3DS2', 'framework_name' => 'Stripe3DS2', 'supports_catalyst' => true })

# Clean build directory
build_dir = File.join_if_safe(root_dir, 'build')

info 'Cleaning build directory...'

FileUtils.rm_rf(build_dir)
Dir.mkdir(build_dir)

Dir.chdir(root_dir) do
  info 'Building all frameworks...'

  info 'Building iOS...'

  # Build for iOS
  puts `xcodebuild clean archive \
    -quiet \
    -workspace "Stripe.xcworkspace" \
    -scheme "AllStripeFrameworks" \
    -configuration "Release" \
    -archivePath "#{build_dir}/StripeFrameworks-iOS.xcarchive" \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    SYMROOT="#{build_dir}/StripeFrameworks-framework-ios" \
    OBJROOT="#{build_dir}/StripeFrameworks-framework-ios" \
    SUPPORTS_MACCATALYST=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE \
    SKIP_INSTALL=NO`

  exit_code = $?.exitstatus
  die "xcodebuild exited with non-zero status code: #{exit_code}" if exit_code != 0

  info 'Building Simulator...'

  # Build for Simulator
  puts `xcodebuild clean archive \
    -quiet \
    -workspace "Stripe.xcworkspace" \
    -scheme "AllStripeFrameworks" \
    -destination 'generic/platform=iOS Simulator' \
    -configuration "Release" \
    -archivePath "#{build_dir}/StripeFrameworks-sim.xcarchive" \
    -sdk iphonesimulator \
    SYMROOT="#{build_dir}/StripeFrameworks-framework-sim" \
    OBJROOT="#{build_dir}/StripeFrameworks-framework-sim" \
    SUPPORTS_MACCATALYST=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE \
    SKIP_INSTALL=NO`

  exit_code = $?.exitstatus
  die "xcodebuild exited with non-zero status code: #{exit_code}" if exit_code != 0

  info 'Building Catalyst...'

  # Build for MacOS
  puts `xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -scheme "AllStripeFrameworksCatalyst" \
      -configuration "Release" \
      -archivePath "#{build_dir}/StripeFrameworks-mac.xcarchive" \
      -sdk macosx \
      -destination 'generic/platform=macOS,variant=Mac Catalyst' \
      SYMROOT="#{build_dir}/StripeFrameworks-framework-mac" \
      OBJROOT="#{build_dir}/StripeFrameworks-framework-mac" \
      SUPPORTS_MACCATALYST=YES \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE \
      SKIP_INSTALL=NO`

  exit_code = $?.exitstatus
  die "xcodebuild exited with non-zero status code: #{exit_code}" if exit_code != 0

  modules.each do |m|
    scheme = m['scheme']
    framework_name = m['framework_name']
    supports_catalyst = m['supports_catalyst']
    platform_frameworks = []
    die 'Module is missing scheme' if scheme.nil? || scheme.empty?
    die 'Module is missing framework_name' if framework_name.nil? || framework_name.empty?

    platform_frameworks.append("-framework \"#{build_dir}/StripeFrameworks-iOS.xcarchive/Products/Library/Frameworks/#{framework_name}.framework\"")

    platform_frameworks.append("-framework \"#{build_dir}/StripeFrameworks-sim.xcarchive/Products/Library/Frameworks/#{framework_name}.framework\"")

    if supports_catalyst
      platform_frameworks.append("-framework \"#{build_dir}/StripeFrameworks-mac.xcarchive/Products/Library/Frameworks/#{framework_name}.framework\"")
    end

    puts `xcodebuild -create-xcframework \
    #{platform_frameworks.join(' ')} \
    -output "#{build_dir}/#{framework_name}.xcframework"`
  end # modules.each
end # Dir.chdir

Zip::File.open(File.join_if_safe(build_dir, 'Stripe.xcframework.zip'), create: true) do |zipfile|
  # Add module framework directories to zip
  modules.each do |m|
    framework_name = m['framework_name']
    Dir.glob("#{build_dir}/#{framework_name}.xcframework/**/*").each do |file|
      file_name = Pathname.new(file).relative_path_from(Pathname.new(build_dir))
      zipfile.add(file_name, file)
    end
  end
end

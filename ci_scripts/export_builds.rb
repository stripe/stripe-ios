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
    raise "Cannot join nil or empty string." if arg.nil? || arg.empty?
  end

  return File.join(args)
end

# MARK: - Main

script_dir = __dir__
root_dir = File.expand_path(File.join_if_safe(script_dir, ".."), Dir.getwd)
modules = YAML.load_file("modules.yaml")['modules']

# Clean build directory
build_dir = File.join_if_safe(root_dir, "build")

info "Cleaning build directory..."

FileUtils.rm_rf(build_dir)
Dir.mkdir(build_dir)

# Compile and package dynamic framework
info "Compiling and packaging dynamic framework..."

Dir.chdir(root_dir) do
  # Build Stripe3DS2
  info "Building Stripe3DS2..."

  `#{root_dir}/stripe3ds2-support/ci_scripts/build_dynamic_xcframework.sh`

  exit_code=$?.exitstatus
  if exit_code != 0
    die "Stripe3DS2 build exited with non-zero status code: #{exit_code}"
  end

  modules.each do |m|
    scheme = m['scheme']
    framework_name = m['framework_name']

    die "Module is missing scheme" if scheme.nil? || scheme.empty?
    die "Module is missing framework_name" if framework_name.nil? || framework_name.empty?

    info "Building #{scheme}..."

    # Build for iOS
    puts `xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -destination="iOS" \
      -scheme "#{scheme}" \
      -configuration "Release" \
      -archivePath "#{build_dir}/#{framework_name}-iOS.xcarchive" \
      -sdk iphoneos \
      SYMROOT="#{build_dir}/#{framework_name}-framework-ios" \
      OBJROOT="#{build_dir}/#{framework_name}-framework-ios" \
      SUPPORTS_MACCATALYST=NO \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      SKIP_INSTALL=NO`

    exit_code=$?.exitstatus
    if exit_code != 0
      die "xcodebuild exited with non-zero status code: #{exit_code}"
    end

    # Build for Simulator
    puts `xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -scheme "#{scheme}" \
      -destination="iOS Simulator" \
      -configuration "Release" \
      -archivePath "#{build_dir}/#{framework_name}-sim.xcarchive" \
      -sdk iphonesimulator \
      SYMROOT="#{build_dir}/#{framework_name}-framework-sim" \
      OBJROOT="#{build_dir}/#{framework_name}-framework-sim" \
      SUPPORTS_MACCATALYST=NO \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      SKIP_INSTALL=NO`

    exit_code=$?.exitstatus
    if exit_code != 0
      die "xcodebuild exited with non-zero status code: #{exit_code}"
    end

    # Build for MacOS
    puts `xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -scheme "#{scheme}" \
      -configuration "Release" \
      -archivePath "#{build_dir}/#{framework_name}-mac.xcarchive" \
      -sdk macosx \
      SYMROOT="#{build_dir}/#{framework_name}-framework-mac" \
      OBJROOT="#{build_dir}/#{framework_name}-framework-mac" \
      SUPPORTS_MACCATALYST=YES \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      SKIP_INSTALL=NO`

    exit_code=$?.exitstatus
    if exit_code != 0
      die "xcodebuild exited with non-zero status code: #{exit_code}"
    end

    codesign_identity=`security find-identity -v -p codesigning | grep Y28TH9SHX7 | grep -o -E '\w{40}' | head -n 1`.strip

    if codesign_identity.nil? || codesign_identity.empty?
      info "Stripe Apple Distribution code signing certificate not found, #{framework_name}.xcframework will not be signed."
      info "Install one from Xcode Settings -> Accounts -> Manage Certificates."
    else
      `codesign -f --deep -s "#{codesign_identity}" "#{build_dir}/#{framework_name}-iOS.xcarchive/Products/Library/Frameworks/#{framework_name}.framework"`
      `codesign -f --deep -s "#{codesign_identity}" "#{build_dir}/#{framework_name}-sim.xcarchive/Products/Library/Frameworks/#{framework_name}.framework"`
      `codesign -f --deep -s "#{codesign_identity}" "#{build_dir}/#{framework_name}-mac.xcarchive/Products/Library/Frameworks/#{framework_name}.framework"`
    end

    puts `xcodebuild -create-xcframework \
    -framework "#{build_dir}/#{framework_name}-iOS.xcarchive/Products/Library/Frameworks/#{framework_name}.framework" \
    -framework "#{build_dir}/#{framework_name}-sim.xcarchive/Products/Library/Frameworks/#{framework_name}.framework" \
    -framework "#{build_dir}/#{framework_name}-mac.xcarchive/Products/Library/Frameworks/#{framework_name}.framework" \
    -output "#{build_dir}/#{framework_name}.xcframework"`

    unless codesign_identity.nil? || codesign_identity.empty?
      `codesign -f --deep -s "#{codesign_identity}" "#{build_dir}/#{framework_name}.xcframework"`
    end

  end # modules.each
end # Dir.chdir

Zip::File.open(File.join_if_safe(build_dir, "Stripe.xcframework.zip"), create: true) do |zipfile|
  # Add Stripe3DS2.xcframework to zip
  stripe3ds2_build_build_dir = File.join_if_safe(root_dir, "build-3ds2")
  Dir.glob("#{stripe3ds2_build_build_dir}/Stripe3DS2.xcframework/**/*").each do |file|
    file_name = Pathname.new(file).relative_path_from(Pathname.new(stripe3ds2_build_build_dir))
    zipfile.add(file_name, file)
  end

  # Add module framework directories to zip
  modules.each do |m|
    framework_name = m['framework_name']
    Dir.glob("#{build_dir}/#{framework_name}.xcframework/**/*").each do |file|
      file_name = Pathname.new(file).relative_path_from(Pathname.new(build_dir))
      zipfile.add(file_name, file)
    end
  end
end

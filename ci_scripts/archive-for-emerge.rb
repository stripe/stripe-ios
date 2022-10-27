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

# Clean build directory
build_dir = File.join_if_safe(root_dir, 'build')

info 'Cleaning build directory...'

FileUtils.rm_rf(build_dir)
Dir.mkdir(build_dir)

# Compile and package dynamic framework
info 'Compiling and packaging dynamic framework...'

Dir.chdir(root_dir) do
  # Build Stripe3DS2
  # info 'Building Stripe3DS2...'

  # `#{root_dir}/stripe3ds2-support/ci_scripts/build_dynamic_xcframework.sh`

  # exit_code = $?.exitstatus
  # die "Stripe3DS2 build exited with non-zero status code: #{exit_code}" if exit_code != 0

  modules.each do |m|
    scheme = m['scheme']
    framework_name = m['framework_name']
    die 'Module is missing scheme' if scheme.nil? || scheme.empty?
    die 'Module is missing framework_name' if framework_name.nil? || framework_name.empty?

    info "Building #{scheme}..."

    info 'Building iOS...'

    # Build for iOS
    puts `xcodebuild clean archive \
      -quiet \
      -workspace "Stripe.xcworkspace" \
      -scheme "#{scheme}" \
      -configuration "Release" \
      -archivePath "#{build_dir}/#{framework_name}-iOS.xcarchive" \
      -sdk iphoneos \
      -destination 'generic/platform=iOS' \
      SYMROOT="#{build_dir}/#{framework_name}-framework-ios" \
      OBJROOT="#{build_dir}/#{framework_name}-framework-ios" \
      SUPPORTS_MACCATALYST=NO \
      LD_GENERATE_MAP_FILE=YES \
      LD_MAP_FILE_PATH="#{build_dir}/#{framework_name}-LinkMap.txt" \
      BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
      SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE \
      SKIP_INSTALL=NO`

    exit_code = $?.exitstatus
    die "xcodebuild exited with non-zero status code: #{exit_code}" if exit_code != 0
    `mkdir #{build_dir}/#{framework_name}-iOS.xcarchive/Linkmaps`
    `mv "#{build_dir}/#{framework_name}-LinkMap.txt" "#{build_dir}/#{framework_name}-iOS.xcarchive/Linkmaps/#{framework_name}-LinkMap.txt"`
  end # modules.each
end # Dir.chdir

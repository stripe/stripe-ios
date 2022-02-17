#!/usr/bin/env ruby

require 'plist'
require 'fileutils'
require 'optparse'
require 'colorize'
require 'yaml'

################################################################################
#
# This script works by building the SPMTest project once without including an
# SDK framework, then including each SDK framework from each of the specified
# branches and building again.
#
# The framework is included in the SPMTest project by apply
# `include_framework.patch` and replacing all occurrances of '{{SDK}}' in the
# patched files with the framework name.
#
# NOTE:
# If you need to update the SPMTest project in any way, the recommended way to
# do this is to:
# 1. Make any necessary edits to the workspace that does not include an SDK
#    framework
# 2. Commit the changes
# 3. Include the Stripe framewwork and make any necessary edits to the project
# 4. Open any files that reference the framework in a text editor and replace
#    "Stripe" with "{{SDK}}" in any relevant files. This includes:
#    - SPMTest.xcodeproj/project.pbxproj
#    - SPMTest/ViewController.swift
# 5. Create a new patch file and save it outside the repo location:
#    git diff > ~/Desktop/include_framework.patch
# 6. Move the file into your cloned repo directory:
#    mv ~/Desktop/include_framework.patch Tests/installation_tests/size_test/include_framework.patch
# 7. commit your changes
#
################################################################################

# MARK: - Helpers

# Redefine backtick to exit the script on failure.
# This is basically `set -e`, but Ruby.
define_method :'`' do |*args|
  puts "> #{args}"
  output = Kernel.send('`', *args)
  exit $?.exitstatus unless $?.success?
  return output
end

def bytes_to_kb(bytes)
  bytes / 1000
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

def info(string)
  puts "[#{File.basename(__FILE__)}] [INFO] #{string}"
end

def die(string)
  abort "[#{File.basename(__FILE__)}] [ERROR] #{string}"
end

def build(dir)
  Dir.chdir(dir) do

    # Xcode's ipatool relies on the system ruby, so break out of Bundler's environment here to avoid
    # "The data couldn’t be read because it isn’t in the correct format" errors.



    Bundler.with_original_env do
      `mkdir -p build`
      # Build an archive with all code-signing disabled
      # (so we can run this in an untrusted CI environment)
      command_succeeded = system("#{'xcodebuild clean archive ' +
        '-quiet ' +
        '-workspace "SPMTest.xcworkspace" ' +
        '-scheme "SPMTest" ' +
        '-sdk "iphoneos" ' +
        '-destination "generic/platform=iOS" ' +
        '-archivePath build/SPMTest.xcarchive ' +
        'CODE_SIGN_IDENTITY="-" ' +
        'CODE_SIGNING_REQUIRED="NO" ' +
        'CODE_SIGN_ENTITLEMENTS="" ' +
        'CODE_SIGNING_ALLOWED="NO"'}")

      unless command_succeeded
        raise StandardError.new "Clean failed"
      end

      # Export a thinned archive for distribution using ad-hoc signing.
      # `ExportOptions.plist` contains a signingCertificate of "-": This isn't
      # documented anywhere, but will cause Xcode to ad-hoc sign the archive.
      # This will create "App Thinning Size Report.txt".
      command_succeeded = system("#{'xcodebuild -exportArchive ' +
      '-quiet '+
      '-archivePath build/SPMTest.xcarchive ' +
      '-exportPath build/SPMTestArchived ' +
      '-exportOptionsPlist ExportOptions.plist ' +
      'CODE_SIGN_IDENTITY="-"'}")

      unless command_succeeded
        raise StandardError.new "Build failed"
      end
    end

    # Find the last app size result (which corresponds to the thinned universal app, not an individual device slice).
    app_size = Plist.parse_xml('build/SPMTestArchived/app-thinning.plist')
    compressed_size = app_size['variants']['Apps/SPMTest.ipa']['sizeCompressedApp']
    uncompressed_size = app_size['variants']['Apps/SPMTest.ipa']['sizeUncompressedApp']
    return bytes_to_kb(compressed_size), bytes_to_kb(uncompressed_size)
  end
end

@script_dir = __dir__
# Find the base of the repo
@project_dir = File.expand_path(File.join_if_safe(@script_dir, "/../../../"), Dir.getwd)

@temp_dir = `mktemp -d`.chomp("\n")

def setup_project(branch, directory, sdk)
  Dir.chdir(@project_dir) do
    `git checkout #{branch}`

    # Clone the size_test app to the tmp directory
    `cp -a "#{@script_dir}/." "#{directory}"`
  end

  Dir.chdir(directory) do
    # We'll want to modify the workspace to point to the checked-out git repo
    File.open('SPMTest.xcworkspace/contents.xcworkspacedata', 'w') do |f|
      f.write <<-CONTENTS
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
  version = "1.0">
  <FileRef
      location = "container:SPMTest.xcodeproj">
  </FileRef>
  <FileRef
      location = "group:#{@project_dir}">
  </FileRef>
</Workspace>
      CONTENTS
    end

    # Include the SDK in the project
    unless sdk.nil?
      # Apply patch adding module named '{{SDK}}'
      patched_files = `patch -p4 < include_framework.patch`.lines.map do |l|
        l.partition('patching file').last.strip
      end

      # Do a find/replace of '{{SDK}}' with SDK name for each patched file
      patched_files.each do |file_name|
        file_contents = File.read(file_name)
        file_contents = file_contents.gsub(/\{\{SDK\}\}/, sdk)

        File.open(file_name, 'w') do |file|
          file.puts file_contents
        end
      end
    end
  end
end

def build_from_branch(branch, dir)
  Dir.chdir(@project_dir) do
    `git checkout #{branch}`
  end
  return build(dir)
end

def check_size(modules, first_branch, second_branch)
  # Try to check out the branches - this will fail if there are unstaged changes,
  # so this also helps prevent us from unintentionally messing up any uncommitted work:
  current_branch = nil
  Dir.chdir(@project_dir) do
    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp("\n")
    `git checkout #{first_branch}`
    `git checkout #{second_branch}` unless second_branch.nil?

    `git checkout #{current_branch}`
  end

  # Build without including the SDK and store the result
  setup_project(current_branch, @temp_dir, nil)
  unincluded_compressed_size, unincluded_uncompressed_size = build(@temp_dir)
  puts "SPMTest #{"without SDK".underline}: Compressed size: #{unincluded_compressed_size}kb, uncompressed size: #{unincluded_uncompressed_size}kb".blue

  sdks_exceeding_max_size = []
  sdks_exceeding_incremental_size = []

  modules.each do |m|
    sdk = m['framework_name']
    max_compressed_size = m['size_report']['max_compressed_size']
    max_uncompressed_size = m['size_report']['max_uncompressed_size']
    max_incremental_uncompressed_size = m['size_report']['max_incremental_uncompressed_size']

    begin
      # Setup project to include SDK
      setup_project(current_branch, @temp_dir, sdk)

      # Checkout first branch and build with SDK
      puts "Building with #{sdk} on #{first_branch}...".green
      first_compressed_size, first_uncompressed_size = build_from_branch(first_branch, @temp_dir)

      first_sdk_compressed = first_compressed_size - unincluded_compressed_size
      first_sdk_uncompressed = first_uncompressed_size - unincluded_uncompressed_size

      puts "SPMTest with #{sdk.underline} on #{first_branch}: Compressed size: #{first_compressed_size}kb, uncompressed size: #{first_uncompressed_size}kb".blue
      puts "Size of #{sdk.underline} on #{first_branch} is #{first_sdk_compressed}kb when compressed, #{first_sdk_uncompressed}kb when uncompressed".blue

      # Checkout second branch and build with SDK
      second_compressed_size, second_uncompressed_size = nil
      unless second_branch.nil?
        puts "Building with #{sdk} on #{second_branch}...".green
        second_compressed_size, second_uncompressed_size = build_from_branch(second_branch, @temp_dir)

        second_sdk_compressed = second_compressed_size - unincluded_compressed_size
        second_sdk_uncompressed = second_uncompressed_size - unincluded_uncompressed_size

        incremental_diff_uncompressed = second_uncompressed_size - first_uncompressed_size
        incremental_diff_compressed = second_compressed_size - first_compressed_size

        puts "SPMTest with #{sdk.underline} on #{second_branch}: Compressed size: #{second_compressed_size}kb, uncompressed size: #{second_uncompressed_size}kb".blue

        puts "Size of #{sdk.underline} on #{second_branch} is #{second_sdk_compressed}kb when compressed, #{second_sdk_uncompressed}kb when uncompressed".blue

        exceeds_max_size = false
        if not(max_compressed_size.nil?) && second_sdk_compressed > max_compressed_size
          puts "This is over the #{max_compressed_size}kb compressed threshold, failing build.".red
          exceeds_max_size = true
        end

        if not(max_uncompressed_size.nil?) && second_sdk_uncompressed > max_uncompressed_size
          puts "This is over the #{max_uncompressed_size}kb uncompressed threshold, failing build.".red
          exceeds_max_size = true
        end

        if exceeds_max_size
          sdks_exceeding_max_size.append(sdk)
        end

        puts "#{second_branch} adds #{incremental_diff_uncompressed}kb when compressed, #{incremental_diff_compressed}kb when uncompressed to #{sdk.underline}".blue
        if not(max_incremental_uncompressed_size.nil?) && incremental_diff_uncompressed > max_incremental_uncompressed_size
          puts "This is over the #{max_incremental_uncompressed_size}kb incremental uncompressed threshold.".red
          sdks_exceeding_incremental_size.append(sdk)
        end
      end
    rescue
        puts "#{sdk} could not be built on one of the specified branches".red
    end
  end

  # Go back to current branch
  Dir.chdir(@project_dir) do
    `git checkout #{current_branch}`
  end

  return sdks_exceeding_max_size, sdks_exceeding_incremental_size
end

if ARGV.empty?
  puts 'Usage: size_report.sh ref [other_ref]'
  puts 'Calculates the App Store thinned size of frameworks when packaged with a basic test app'
  puts 'Only frameworks with `size_report` specified in modules.yaml will have a size report'
  puts 'ref: the tag/branch to be calculated (e.g. private)'
  puts 'other_ref (optional): a tag/branch to compare (e.g. 21.1.0)'
  exit 1
end

first_branch = ARGV[0]
second_branch = ARGV[1]

modules = YAML.load_file(File.join_if_safe(@project_dir, "modules.yaml"))['modules'].select { |m| !m['size_report'].nil? }
sdks_exceeding_max_size, sdks_exceeding_incremental_size = check_size(modules, first_branch, second_branch)

# Clean up temp directory
FileUtils.rm_rf(@temp_dir)

# If one or more SDKs exceed the incremental size, then warn.
unless sdks_exceeding_incremental_size.empty?
  puts "The following SDKs exceed the maximum allowed incremental size: #{sdks_exceeding_incremental_size.join(", ")}".red
end

# If one or more SDKs exceed the maximum allowable size, fail.
unless sdks_exceeding_max_size.empty?
  puts "The following SDKs exceed the maximum allowed size: #{sdks_exceeding_max_size.join(", ")}".red
  exit 1
end

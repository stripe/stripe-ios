#!/usr/bin/env ruby

require 'plist'
require 'fileutils'
require 'optparse'
require 'colorize'
require 'yaml'
require 'terminal-table'

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

# Local runs don't set this env variable, defaulting to the stripe repo so the report is run.
pr_repo_url = ENV["BITRISEIO_PULL_REQUEST_REPOSITORY_URL"] ||= 'https://github.com/stripe/stripe-ios.git'
unless pr_repo_url.include? 'github.com/stripe/stripe-ios'
  puts 'Size report can only be run on Stripe PRs, skipping.'
  exit 0
end

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

def format_size(kilobytes)
  "#{kilobytes}kb"
end

def format_delta(delta)
  return '--' if delta.zero?

  if delta.positive?
    "+#{format_size(delta)}".red
  else
    format_size(delta).green
  end
end

def format_result(exceeds_max_size:, exceeds_max_incremental_size:)
  return '❌' if exceeds_max_size

  exceeds_max_incremental_size ? '🟡' : '✅'
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

def info(string)
  puts "[#{File.basename(__FILE__)}] [INFO] #{string}"
end

def die(string)
  abort "[#{File.basename(__FILE__)}] [ERROR] #{string}"
end

def build(dir, target_name = 'SPMTest')
  Dir.chdir(dir) do
    # Xcode's ipatool relies on the system ruby, so break out of Bundler's environment here to avoid
    # "The data couldn’t be read because it isn’t in the correct format" errors.

    Bundler.with_original_env do
      `mkdir -p build`
      # Build an archive with all code-signing disabled
      # (so we can run this in an untrusted CI environment)
      command_succeeded = system(('xcodebuild clean archive ' +
        '-quiet ' +
        '-workspace "SPMTest.xcworkspace" ' +
        '-scheme "SPMTest" ' +
        '-sdk "iphoneos" ' +
        '-destination "generic/platform=iOS" ' +
        '-archivePath build/SPMTest.xcarchive ' +
        'CODE_SIGN_IDENTITY="-" ' +
        'CODE_SIGNING_REQUIRED="NO" ' +
        'CODE_SIGN_ENTITLEMENTS="" ' +
        'LD_GENERATE_MAP_FILE="YES" ' +
        "LD_MAP_FILE_PATH=\"build/#{target_name}-LinkMap.txt\" " +
        'CODE_SIGNING_ALLOWED="NO"').to_s)

      raise StandardError, 'Build failed' unless command_succeeded

      # Export a thinned archive for distribution using ad-hoc signing.
      # `ExportOptions.plist` contains a signingCertificate of "-": This isn't
      # documented anywhere, but will cause Xcode to ad-hoc sign the archive.
      # This will create "App Thinning Size Report.txt".
      command_succeeded = system(('xcodebuild -exportArchive ' +
      '-quiet ' +
      '-archivePath build/SPMTest.xcarchive ' +
      '-exportPath build/SPMTestArchived ' +
      '-exportOptionsPlist ExportOptions.plist ' +
      'CODE_SIGN_IDENTITY="-"').to_s)

      raise StandardError, 'Build failed' unless command_succeeded
    end

    # Find the last app size result (which corresponds to the thinned universal app, not an individual device slice).
    app_size = Plist.parse_xml('build/SPMTestArchived/app-thinning.plist')
    compressed_size = app_size['variants']["Apps/#{target_name}.ipa"]['sizeCompressedApp']
    uncompressed_size = app_size['variants']["Apps/#{target_name}.ipa"]['sizeUncompressedApp']
    return bytes_to_kb(compressed_size), bytes_to_kb(uncompressed_size)
  end
end

@script_dir = __dir__
# Find the base of the repo
@project_dir = File.expand_path(File.join_if_safe(@script_dir, '/../../../'), Dir.getwd)

@temp_dir = `mktemp -d`.chomp("\n")

@archive_dir = "#{@project_dir}/build/size_tests"
FileUtils.rm_rf(@archive_dir)
`mkdir -p #{@archive_dir}`

def setup_project(branch, directory, sdk)
  Dir.chdir(@project_dir) do
    `git checkout #{branch}`

    # Clone the size_test app to the tmp directory
    `cp -a "#{@script_dir}/." "#{directory}"`
  end

  Dir.chdir(directory) do
    # We'll want to modify the workspace to point to the checked-out git repo
    File.open('SPMTest.xcworkspace/contents.xcworkspacedata', 'w') do |f|
      f.write <<~CONTENTS
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
        l.partition('patching file').last.strip.tr("'", '') # Recent versions of patch in macOS add a ' to the filename
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

def build_from_branch(branch, dir, target_name)
  Dir.chdir(@project_dir) do
    `git checkout #{branch}`
  end
  build(dir, target_name)
end

def check_size(modules, measure_branch, base_branch)
  # Try to check out the branches - this will fail if there are unstaged changes,
  # so this also helps prevent us from unintentionally messing up any uncommitted work:
  current_branch = nil
  Dir.chdir(@project_dir) do
    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp("\n")
    `git checkout #{measure_branch}`
    `git checkout #{base_branch}` unless base_branch.nil?

    `git checkout #{current_branch}`
  end

  # Build without including the SDK and store the result
  setup_project(current_branch, @temp_dir, nil)
  unincluded_compressed_size, unincluded_uncompressed_size = build(@temp_dir)
  puts "SPMTest #{'without SDK'.underline}: Compressed size: #{unincluded_compressed_size}kb, uncompressed size: #{unincluded_uncompressed_size}kb".blue

  sdks_exceeding_max_size = []
  sdks_exceeding_incremental_size = []

  size_report = Terminal::Table.new(
    title: 'Size report',
    headings: [
      'Module',
      'Compressed size',
      'Uncompressed size',
      'Delta (Comp.)',
      'Delta (Uncomp.)',
      'Result'
    ]
  )

  modules.each do |m|
    sdk = m['framework_name']
    max_compressed_size = m['size_report']['max_compressed_size']
    max_uncompressed_size = m['size_report']['max_uncompressed_size']
    max_incremental_uncompressed_size = m['size_report']['max_incremental_uncompressed_size']

    begin
      # Setup project to include SDK
      setup_project(current_branch, @temp_dir, sdk)

      # Checkout measure branch and build with SDK
      puts "Building with #{sdk} on #{measure_branch}...".green
      measure_compressed_size, measure_uncompressed_size = build_from_branch(measure_branch, @temp_dir, sdk + 'Size')

      # Keep the xcarchive around to send to Emerge
      `mkdir -p "#{@temp_dir}/build/SPMTest.xcarchive/Linkmaps/"`
      `cp "#{@temp_dir}/build/#{sdk}Size-LinkMap.txt" "#{@temp_dir}/build/SPMTest.xcarchive/Linkmaps/"`
      `mv "#{@temp_dir}/build/SPMTest.xcarchive" "#{@archive_dir}/#{sdk}.xcarchive"`

      measure_sdk_compressed = measure_compressed_size - unincluded_compressed_size
      measure_sdk_uncompressed = measure_uncompressed_size - unincluded_uncompressed_size

      puts "SPMTest with #{sdk.underline} on #{measure_branch}: Compressed size: #{format_size(measure_compressed_size)}, uncompressed size: #{format_size(measure_uncompressed_size)}".blue
      puts "Size of #{sdk.underline} on #{measure_branch} is #{format_size(measure_sdk_compressed)} when compressed, #{format_size(measure_sdk_uncompressed)} when uncompressed".blue

      # Checkout base branch and build with SDK
      base_compressed_size, base_uncompressed_size = nil
      unless base_branch.nil?
        puts "Building with #{sdk} on #{base_branch}...".green
        base_compressed_size, base_uncompressed_size = build_from_branch(base_branch, @temp_dir, sdk + 'Size')

        base_sdk_compressed = base_compressed_size - unincluded_compressed_size
        base_sdk_uncompressed = base_uncompressed_size - unincluded_uncompressed_size

        incremental_diff_uncompressed = measure_uncompressed_size - base_uncompressed_size
        incremental_diff_compressed = measure_compressed_size - base_compressed_size

        puts "SPMTest with #{sdk.underline} on #{base_branch}: Compressed size: #{format_size(base_compressed_size)}, uncompressed size: #{format_size(base_uncompressed_size)}".blue

        puts "Size of #{sdk.underline} on #{base_branch} is #{format_size(base_sdk_compressed)} when compressed, #{format_size(base_sdk_uncompressed)} when uncompressed".blue

        exceeds_max_size = false
        if !max_compressed_size.nil? && measure_sdk_compressed > max_compressed_size
          puts "This is over the #{max_compressed_size}kb compressed threshold, failing build.".red
          exceeds_max_size = true
        end

        if !max_uncompressed_size.nil? && measure_sdk_uncompressed > max_uncompressed_size
          puts "This is over the #{max_uncompressed_size}kb uncompressed threshold, failing build.".red
          exceeds_max_size = true
        end

        sdks_exceeding_max_size.append(sdk) if exceeds_max_size

        puts "#{measure_branch} adds #{incremental_diff_uncompressed}kb when compressed, #{incremental_diff_compressed}kb when uncompressed to #{sdk.underline}".blue
        exceeds_max_incremental_size = false
        if !max_incremental_uncompressed_size.nil? && incremental_diff_uncompressed > max_incremental_uncompressed_size
          puts "This is over the #{max_incremental_uncompressed_size}kb incremental uncompressed threshold.".red
          exceeds_max_incremental_size = true
          sdks_exceeding_incremental_size.append(sdk)
        end

        size_report << [
          sdk,
          format_size(measure_sdk_compressed),
          format_size(measure_sdk_uncompressed),
          format_delta(incremental_diff_compressed),
          format_delta(incremental_diff_uncompressed),
          format_result(
            exceeds_max_size: exceeds_max_size,
            exceeds_max_incremental_size: exceeds_max_incremental_size
          )
        ]
      end
    rescue StandardError => e
      puts "#{sdk} could not be built on one of the specified branches".red
      puts e.message.to_s.red
    end
  end

  # Go back to current branch
  Dir.chdir(@project_dir) do
    `git checkout #{current_branch}`
  end

  # Print size report table
  (0..4).each { |col| size_report.align_column(col, :right) }
  puts size_report

  [sdks_exceeding_max_size, sdks_exceeding_incremental_size]
end

if ARGV.empty?
  puts 'Usage: size_report.sh ref [other_ref]'
  puts 'Calculates the App Store thinned size of frameworks when packaged with a basic test app'
  puts 'Only frameworks with `size_report` specified in modules.yaml will have a size report'
  puts 'ref: the tag/branch to be calculated (e.g. master)'
  puts 'other_ref (optional): a tag/branch to compare (e.g. 21.1.0)'
  exit 1
end

measure_branch = ARGV[0]
base_branch = ARGV[1]

modules = YAML.load_file(File.join_if_safe(@project_dir, 'modules.yaml'))['modules'].select { |m| !m['size_report'].nil? }
sdks_exceeding_max_size, sdks_exceeding_incremental_size = check_size(modules, measure_branch, base_branch)

# Clean up temp directory
FileUtils.rm_rf(@temp_dir)

# If one or more SDKs exceed the incremental size, then warn.
unless sdks_exceeding_incremental_size.empty?
  puts "The following SDKs exceed the maximum allowed incremental size: #{sdks_exceeding_incremental_size.join(', ')}".red
end

# If one or more SDKs exceed the maximum allowable size, fail.
unless sdks_exceeding_max_size.empty?
  puts "The following SDKs exceed the maximum allowed size: #{sdks_exceeding_max_size.join(', ')}".red
  exit 1
end

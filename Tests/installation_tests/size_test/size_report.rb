#!/usr/bin/env ruby

# Build will fail if more than X kb are added.
COMPLAIN_THRESHOLD=100

require 'plist'
require 'fileutils'

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

if ARGV.empty?
  puts 'Usage: size_report.sh ref [other_ref]'
  puts 'Calculates the App Store thinned size of Stripe.framework when packaged with a basic test app'
  puts 'ref: the tag/branch to be calculated (e.g. private)'
  puts 'other_ref (optional): a tag/branch to compare (e.g. 21.1.0)'
  exit 1
end

first_branch = ARGV[0]
second_branch = ARGV[1]

script_dir = __dir__
# Find the base of the repo
project_dir = File.expand_path(File.join_if_safe(script_dir, "/../../../"), Dir.getwd)

temp_dir = `mktemp -d`.chomp("\n")

current_branch=nil
Dir.chdir(project_dir) do
  # Try to check out the branches - this will fail if there are unstaged changes,
  # so this also helps prevent us from unintentionally messing up any uncommitted work:
  current_branch=`git rev-parse --abbrev-ref HEAD`.chomp("\n")
  `git checkout #{first_branch}`
  `git checkout #{second_branch}` unless second_branch.nil?

  `git checkout #{current_branch}`
  # Clone the size_test app to the tmp directory
  `cp -a "#{script_dir}/." "#{temp_dir}"`

  # Check out branch #1
  `git checkout #{first_branch}`
end

Dir.chdir(temp_dir) do
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
      location = "group:#{project_dir}">
  </FileRef>
</Workspace>
    CONTENTS
  end
end

def build(dir)
  Dir.chdir(dir) do

    # Xcode's ipatool relies on the system ruby, so break out of Bundler's environment here to avoid 
    # "The data couldn’t be read because it isn’t in the correct format" errors.
    Bundler.with_original_env do
      `mkdir -p build`
      # Build an archive with all code-signing disabled
      # (so we can run this in an untrusted CI environment)
      `#{'xcodebuild clean archive ' +
        '-quiet ' +
        '-workspace "SPMTest.xcworkspace" ' +
        '-scheme "SPMTest" ' +
        '-sdk "iphoneos" ' +
        '-destination "generic/platform=iOS" ' +
        '-archivePath build/SPMTest.xcarchive ' +
        'CODE_SIGN_IDENTITY="-" ' +
        'CODE_SIGNING_REQUIRED="NO" ' +
        'CODE_SIGN_ENTITLEMENTS="" ' +
        'CODE_SIGNING_ALLOWED="NO"'}`

      # Export a thinned archive for distribution using ad-hoc signing.
      # `ExportOptions.plist` contains a signingCertificate of "-": This isn't
      # documented anywhere, but will cause Xcode to ad-hoc sign the archive.
      # This will create "App Thinning Size Report.txt".
      `#{'xcodebuild -exportArchive ' +
      '-quiet '+
      '-archivePath build/SPMTest.xcarchive ' +
      '-exportPath build/SPMTestArchived ' +
      '-exportOptionsPlist ExportOptions.plist ' +
      'CODE_SIGN_IDENTITY="-"'}`
    end

    # Find the last app size result (which corresponds to the thinned universal app, not an individual device slice).
    app_size = Plist.parse_xml('build/SPMTestArchived/app-thinning.plist')
    compressed_size = app_size['variants']['Apps/SPMTest.ipa']['sizeCompressedApp']
    uncompressed_size = app_size['variants']['Apps/SPMTest.ipa']['sizeUncompressedApp']
    return bytes_to_kb(compressed_size), bytes_to_kb(uncompressed_size)
  end
end

# Do the above build and store the result
first_compressed_size, first_uncompressed_size = build(temp_dir)

second_compressed_size, second_uncompressed_size = nil
unless second_branch.nil?
  Dir.chdir(project_dir) do
    `git checkout #{second_branch}`
  end
  second_compressed_size, second_uncompressed_size = build(temp_dir)
end

# Go back to current branch
Dir.chdir(project_dir) do
  `git checkout #{current_branch}`
end

puts "#{first_branch}: Compressed size: #{first_compressed_size}kb, uncompressed size: #{first_uncompressed_size}kb"
unless second_branch.nil?
  puts "#{second_branch}: Compressed size: #{second_compressed_size}kb, uncompressed size: #{second_uncompressed_size}kb"
  diff_compressed = second_compressed_size - first_compressed_size
  diff_uncompressed = second_uncompressed_size - first_uncompressed_size
  puts "#{second_branch} adds #{diff_compressed}kb when compressed, #{diff_uncompressed}kb when uncompressed"
  if diff_uncompressed > COMPLAIN_THRESHOLD
    puts "This is over the #{COMPLAIN_THRESHOLD}kb uncompressed threshold, failing build."
    exit 1
  end

end

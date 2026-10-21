#!/usr/bin/env ruby

require 'fileutils'
require 'open3'
require 'tmpdir'
require_relative 'get_frameworks'
require_relative 'interface_cache'

def run!(*command)
  abort("Command failed: #{command.first}") unless system(*command)
end

revision, output_directory, fingerprint = ARGV
abort('Usage: build_xcframeworks.rb REVISION OUTPUT_DIRECTORY FINGERPRINT') unless ARGV.length == 3
abort('Expected an immutable commit SHA') unless revision.match?(/\A[0-9a-f]{40}\z/)
abort('Expected a cache fingerprint') unless fingerprint.match?(/\A[0-9a-f]{64}\z/)

output_directory = File.expand_path(output_directory)
begin
  InterfaceCache.load!(output_directory, revision: revision, fingerprint: fingerprint)
  puts "Reusing public interfaces for #{revision}"
  exit
rescue InterfaceCache::InvalidCache => e
  puts "Building public interfaces for #{revision}: #{e.message}"
end

repository, status = Open3.capture2('git', 'rev-parse', '--show-toplevel')
abort('Cannot determine repository root') unless status.success?
build_root = File.join(repository.strip, '.build', 'api-diff')
FileUtils.mkdir_p(build_root)

Dir.mktmpdir('archive-', build_root) do |temporary_directory|
  source_directory = File.join(temporary_directory, 'source')
  archive_path = File.join(temporary_directory, 'frameworks.xcarchive')
  interfaces_path = File.join(temporary_directory, 'interfaces')
  begin
    run!('git', 'worktree', 'add', '--detach', source_directory, revision)
    framework_names = GetFrameworks.framework_names(File.join(source_directory, 'modules.yaml'))

    # The comparison uses only arm64 interfaces; no XCFramework packaging is needed.
    run!(
      'xcodebuild', 'archive', '-quiet',
      '-workspace', File.join(source_directory, 'Stripe.xcworkspace'),
      '-scheme', 'AllStripeFrameworks',
      '-destination', 'generic/platform=iOS Simulator',
      '-configuration', 'Release',
      '-archivePath', archive_path,
      '-derivedDataPath', File.join(temporary_directory, 'DerivedData'),
      '-sdk', 'iphonesimulator',
      'ARCHS=arm64', 'ONLY_ACTIVE_ARCH=YES', 'CODE_SIGNING_ALLOWED=NO',
      'SUPPORTS_MACCATALYST=NO', 'BUILD_LIBRARIES_FOR_DISTRIBUTION=YES',
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS=STRIPE_BUILD_PACKAGE', 'SKIP_INSTALL=NO'
    )

    framework_names.each do |framework_name|
      destination = File.join(interfaces_path, framework_name)
      FileUtils.mkdir_p(destination)
      InterfaceCache::FILENAMES.each do |filename|
        source = File.join(archive_path, 'Products', 'Library', 'Frameworks',
                           "#{framework_name}.framework", 'Modules', "#{framework_name}.swiftmodule", filename)
        abort("Missing generated interface: #{source}") unless File.file?(source) && File.size?(source)
        FileUtils.cp(source, destination)
      end
    end

    InterfaceCache.write!(interfaces_path, revision: revision, fingerprint: fingerprint, frameworks: framework_names)
    FileUtils.rm_rf(output_directory)
    FileUtils.mkdir_p(File.dirname(output_directory))
    FileUtils.mv(interfaces_path, output_directory)
  ensure
    # Never switch the caller's checkout: its scripts and changelog must stay on the PR revision.
    run!('git', 'worktree', 'remove', '--force', source_directory) if File.directory?(source_directory)
  end
end

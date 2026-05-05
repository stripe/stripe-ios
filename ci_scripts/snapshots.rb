#!/usr/bin/env ruby

require 'optparse'
require 'pathname'

SCRIPT_DIR = __dir__
abort 'Unable to find SCRIPT_DIR' if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?

ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
abort 'Unable to find ROOT_DIR' if ROOT_DIR.nil? || ROOT_DIR.empty?
ROOT_DIR_PATHNAME = Pathname(ROOT_DIR)

Dir.chdir(ROOT_DIR)

scheme = "AllStripeFrameworks"
ci_mode = false

OptionParser.new do |opts|
  opts.banner = "Snapshot tool for stripe-ios\n Usage: snapshots.rb [options]"

  opts.on("--record", "Record snapshots") do |s|
    scheme = "AllStripeFrameworks-RecordMode"
  end

  opts.on("--ci", "CI mode: skip OS version check, use any available simulator") do |s|
    ci_mode = true
  end
end.parse!

device_model = nil
os_version = nil
# Get the device model and OS version
File.open("StripeCore/StripeCoreTestUtils/STPSnapshotTestCase.swift", "r").each_line do |file|
  file.each_line do |line|
    # Get the comment after the device model ("iPhone 12 mini"), not the device model itself ("iPhone13,1")
    if line =~ /let TEST_DEVICE_MODEL = "(.*)" \/\/ (.*)/
      device_model = $2
    elsif line =~ /let TEST_DEVICE_OS_VERSION = "(.*)"/
      os_version = $1
    end
  end
end

if ci_mode
  # In CI mode, find the OS version of the available simulator matching the device
  available_version = `xcrun simctl list devices available`.scan(/#{Regexp.escape(device_model)} \(.*?\) \(([^)]+)\)/).flatten
                       .reject { |state| state == "Shutdown" || state == "Booted" }
  # Parse from the runtime list instead
  available_version = `xcrun simctl list devices available -j`
  require 'json'
  devices = JSON.parse(available_version)['devices']
  os_version = nil
  devices.each do |runtime, device_list|
    next unless runtime.include?('iOS')
    device_list.each do |d|
      if d['name'] == device_model
        # Extract version from runtime identifier (e.g., com.apple.CoreSimulator.SimRuntime.iOS-26-2 -> 26.2)
        os_version = runtime.scan(/iOS[- ](\d+[.-]\d+)/).flatten.first&.tr('-', '.')
        break
      end
    end
    break if os_version
  end
  abort "Could not find OS version for #{device_model}" if os_version.nil?
end

system "./ci_scripts/test.rb --only-snapshot-tests --scheme #{scheme} --device \"#{device_model}\" --version \"#{os_version}\""
print "\a" # done!
#!/usr/bin/env ruby

require 'optparse'

SCRIPT_DIR = __dir__
abort 'Unable to find SCRIPT_DIR' if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?

ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
abort 'Unable to find ROOT_DIR' if ROOT_DIR.nil? || ROOT_DIR.empty?
ROOT_DIR_PATHNAME = Pathname(ROOT_DIR)

Dir.chdir(ROOT_DIR)

scheme = "AllStripeFrameworks"

OptionParser.new do |opts|
  opts.banner = "Snapshot tool for stripe-ios\n Usage: snapshots.rb [options]"

  opts.on("--record", "Record snapshots") do |s|
    scheme = "AllStripeFrameworks-RecordMode"
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

system "./ci_scripts/test.rb --only-snapshot-tests --scheme #{scheme} --device \"#{device_model}\" --version \"#{os_version}\""
print "\a" # done!
#!/usr/bin/env ruby


Dir.chdir(__dir__ + '/..') do
  # Get the device model and OS version
  File.open("StripeCore/StripeCoreUtils/STPSnapshotTestCase.swift", "r").each_line do |line|
    file.each_line do |line|
      if line =~ /^let TEST_DEVICE_MODEL = "(.*)" \/
        puts "Device model: #{$1}"
      elsif line =~ /^let TEST_DEVICE_OS_VERSION = "(.*)"/
        puts "OS Version: #{$1}"
      end
    end
  end

  # `./ci_scripts/test.rb --only-snapshot-tests --scheme StripePaymentsUI --device "iPhone 12 mini" --version "16.4"`
end

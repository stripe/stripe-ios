#!/usr/bin/env ruby

require 'colorize'
require 'English'

# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
MIN_SUPPORTED_XCODE_VERSION = '14.1'.freeze

def verify_xcode_version
  # Verify that xcode-select -p returns the correct version for building Stripe.xcframework.
  unless `xcodebuild -version`.include?("Xcode #{MIN_SUPPORTED_XCODE_VERSION}")
    rputs "Xcode #{MIN_SUPPORTED_XCODE_VERSION} is required to build Stripe.xcframework."
    rputs 'Use `xcode-select -s` to select the correct version, or download it from https://developer.apple.com/download/more/.'
    rputs "If you believe this is no longer the correct version, update `MIN_SUPPORTED_XCODE_VERSION` in `#{__FILE__}`."
    abort
  end
end

def rputs(string)
  puts string.red
end

def run_command(command, raise_on_failure = true)
  puts "> #{command}".blue
  system(command.to_s)
  return unless $CHILD_STATUS.exitstatus != 0

  rputs "Command failed: #{command} \a"
  raise if raise_on_failure
end

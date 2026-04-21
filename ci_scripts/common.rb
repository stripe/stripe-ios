#!/usr/bin/env ruby

require 'colorize'
require 'English'
require 'net/http'
require 'json'
require 'uri'

# The name of the VM for the Xcode version
# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
VM_NAME = 'tahoe-xcode:26.1'.freeze

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

# React Native CI Integration helpers
def get_stripe_react_native_stripe_ios_version
  podspec_url = 'https://raw.githubusercontent.com/stripe/stripe-react-native/refs/heads/master/stripe-react-native.podspec'

  uri = URI(podspec_url)
  response = Net::HTTP.get_response(uri)

  unless response.is_a?(Net::HTTPSuccess)
    return nil
  end

  content = response.body
  match = content.match(/stripe_version\s*=\s*['"]~>\s*(\d+\.\d+)\.\d+['"]/)

  return nil unless match

  match[1] # Returns "25.7"
rescue => e
  nil
end

def should_test_react_native?(release_version)
  rn_version_prefix = get_stripe_react_native_stripe_ios_version

  return false if rn_version_prefix.nil?

  # Extract major.minor from release version (e.g., "25.7" from "25.7.2")
  release_version_prefix = release_version.match(/^(\d+\.\d+)/)[1]

  rn_version_prefix == release_version_prefix
end

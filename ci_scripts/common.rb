#!/usr/bin/env ruby

require 'colorize'
require 'English'

# The name of the VM for the Xcode version
# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
VM_NAME = 'sonoma-xcode:15.0'.freeze

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

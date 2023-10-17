#!/usr/bin/env ruby

require 'colorize'
require 'English'
require 'net/ssh'

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

def run_command_vm(command, raise_on_failure = true)
  tart_pid = spawn("tart run my-ventura-xcode --dir=stripe-ios:/Users/davidestes/stripe/stripe-ios-private")
  Process.detach(tart_pid)
  puts "tart> #{command}".blue

  Net::SSH.start(`tart ip my-ventura-xcode`.strip, 'admin', :password => "admin") do |ssh|
    # capture all stderr and stdout output from a remote process
    output = ssh.exec!("mkdir -p /tmp/build/stripe-ios")
    puts output
    output = ssh.exec!("rsync -a --delete --exclude '.git' \"/Volumes/My Shared Files/stripe-ios\" /tmp/build/")
    puts output
    output = ssh.exec!("cd \"/tmp/build/stripe-ios\" && #{command}")
    puts output
    output = ssh.exec!("rsync -aO --exclude '.git' /tmp/build/stripe-ios/ \"/Volumes/My Shared Files/stripe-ios/\"")
    puts output
  end

  # Process.kill("HUP", tart_pid)
  # return unless $CHILD_STATUS.exitstatus != 0

  # rputs "Command failed: #{command} \a"
  # raise if raise_on_failure
end
# run_command_vm('sudo gem install bundler:2.1.2')
# run_command_vm('bundle install')
# run_command_vm('source ~/.zprofile && brew install tuist')
# run_command_vm('source ~/.zprofile && tuist generate -n')
# run_command_vm('source ~/.zprofile && bundle install')
run_command_vm('source ~/.zprofile && tuist generate -n && bundle exec ./ci_scripts/export_builds.rb')
#!/usr/bin/env ruby

require 'colorize'
require 'English'
require 'net/ssh'
require 'git'

# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
MIN_SUPPORTED_XCODE_VERSION = '14.1'.freeze

# The name of the VM for the Xcode version
# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
VM_NAME = 'ventura-xcode:14.1'.freeze

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
  puts "tart> #{command}".blue

  Net::SSH.start(`tart ip builder-vm`.strip, 'admin', :password => "admin") do |ssh|
    ssh.exec!('mkdir -p "/tmp/build/stripe-ios"')
    output = ssh.exec!("cd \"/tmp/build/stripe-ios\" && #{command}")
    puts output
  end

  # Process.kill("HUP", tart_pid)
  # return unless $CHILD_STATUS.exitstatus != 0

  # rputs "Command failed: #{command} \a"
  # raise if raise_on_failure
end

def bring_up_vm_and_wait_for_boot
  # Try to stop/delete the VM, ignoring failures:
  `tart stop builder-vm`
  `tart delete builder-vm`

  # Create a new VM
  run_command("tart clone #{VM_NAME} builder-vm")
  tart_pid = spawn("tart run builder-vm --dir=stripe-ios:/Users/davidestes/stripe/stripe-ios")
  Process.detach(tart_pid)
  # Retry a basic command every ten seconds until the VM boots, catch error and retry
  booted = false
  until booted
    begin
      run_command_vm('echo hello world')  
      booted = true
    rescue => exception
      puts 'Not online yet, retrying...'
      sleep(10)
    end
  end
  # Copy files to VM
  run_command_vm("mkdir -p /tmp/build/stripe-ios")
  run_command_vm("rsync -a --delete --exclude '.git' \"/Volumes/My Shared Files/stripe-ios\" /tmp/build/")
end

def setup_vm_requirements
  # Clone the repo:
  `git clone org-13141669@github.com:stripe-ios/ios-deploy-vm.git #{Dir.home}/stripe/ios-deploy-vm`
  `cd #{Dir.home}/stripe/ios-deploy-vm && git fetch origin && git checkout origin/#{VM_NAME.sub(':', '_')}`
end

def finish_vm
  # Copy files from VM
  run_command_vm("rsync -aO --exclude '.git' /tmp/build/stripe-ios/ \"/Volumes/My Shared Files/stripe-ios/\"")
  
end

def need_to_build_vm?
  !`tart list`.include? VM_NAME
end

def build_vm
  rputs 'Building VM images! This will take a while, grab some coffee and keep your Mac awake...'
  setup_vm_requirements
  Dir.chdir("#{Dir.home}/stripe/ios-deploy-vm") do
    unless `tart list`.include? 'ventura-vanilla'
      run_command('packer build -var-file="variables.pkrvars.hcl" templates/vanilla-ventura.pkr.hcl')
    end
    unless `tart list`.include? 'ventura-base'
      run_command('packer build -var-file="variables.pkrvars.hcl" templates/base.pkr.hcl')
    end
    run_command('packer build -var-file="variables.pkrvars.hcl" templates/xcode.pkr.hcl')
  end
end

if need_to_build_vm?
  build_vm
end
bring_up_vm_and_wait_for_boot
run_command_vm('source ~/.zprofile && sudo gem install bundler:2.1.2 && bundle install && tuist generate -n && bundle exec ./ci_scripts/export_builds.rb')
finish_vm
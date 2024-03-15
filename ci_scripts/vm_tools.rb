#!/usr/bin/env ruby

require_relative 'common'
require 'net/ssh'

def run_command_vm(command, _raise_on_failure = true)
  puts "tart> #{command}".blue

  Net::SSH.start(`tart ip builder-vm`.strip, 'admin', password: 'admin', config: false) do |ssh|
    ssh.exec!('mkdir -p "/tmp/build/stripe-ios"')
    output = ssh.exec!("cd \"/tmp/build/stripe-ios\" && #{command}")
    puts output
  end
end

def bring_up_vm_and_wait_for_boot
  # Try to stop/delete the VM, ignoring failures:
  `tart stop builder-vm`
  `tart delete builder-vm`

  # Create a new VM
  run_command("tart clone #{VM_NAME} builder-vm")
  tart_pid = spawn("tart run builder-vm --dir=stripe-ios:#{Dir.pwd}")
  Process.detach(tart_pid)
  # Retry a basic command every ten seconds until the VM boots, catch error and retry
  booted = false
  until booted
    begin
      run_command_vm('echo hello world')
      booted = true
    rescue StandardError => e
      puts e
      puts 'Not online yet, retrying...'
      sleep(10)
    end
  end
  # Copy files to VM
  run_command_vm('mkdir -p /tmp/build/stripe-ios')
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
  run_command('tart stop builder-vm')
end

def need_to_build_vm?
  !`tart list`.include? VM_NAME
end

def build_vm
  rputs 'Building VM images! This will take a while, grab some coffee and keep your Mac awake...'
  setup_vm_requirements
  Dir.chdir("#{Dir.home}/stripe/ios-deploy-vm") do
    run_command('packer init -var-file="variables.pkrvars.hcl" templates/vanilla-sonoma.pkr.hcl')
    unless `tart list`.include? 'sonoma-vanilla'
      run_command('packer build -var-file="variables.pkrvars.hcl" templates/vanilla-sonoma.pkr.hcl')
    end
    unless `tart list`.include? 'sonoma-base'
      run_command('packer build -var-file="variables.pkrvars.hcl" templates/base.pkr.hcl')
    end
    run_command('packer build -var-file="variables.pkrvars.hcl" templates/xcode.pkr.hcl')
  end
end

#!/usr/bin/env ruby

require 'optparse'

SCRIPT_DIR = __dir__
abort 'Unable to find SCRIPT_DIR' if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?

ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
abort 'Unable to find ROOT_DIR' if ROOT_DIR.nil? || ROOT_DIR.empty?

Dir.chdir(ROOT_DIR)

DEVICE_MODEL = 'iPhone 12 mini'
OS_VERSION = '16.4'

scheme = 'AllStripeFrameworks'

OptionParser.new do |opts|
  opts.banner = "Snapshot tool for stripe-ios\n Usage: snapshots.rb [options]"

  opts.on('--record', 'Record snapshots') do
    scheme = 'AllStripeFrameworks-RecordMode'
  end
end.parse!

system('./ci_scripts/test.rb', '--only-snapshot-tests',
       '--scheme', scheme,
       '--device', DEVICE_MODEL,
       '--version', OS_VERSION)
exit($?.exitstatus || 1)

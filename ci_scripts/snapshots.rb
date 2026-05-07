#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'pathname'

SCRIPT_DIR = __dir__
abort 'Unable to find SCRIPT_DIR' if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?

ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
abort 'Unable to find ROOT_DIR' if ROOT_DIR.nil? || ROOT_DIR.empty?

Dir.chdir(ROOT_DIR)

DEVICE_MODEL = 'iPhone 12 mini'

scheme = 'AllStripeFrameworks'
ci_mode = false

OptionParser.new do |opts|
  opts.banner = "Snapshot tool for stripe-ios\n Usage: snapshots.rb [options]"

  opts.on('--record', 'Record snapshots') do
    scheme = 'AllStripeFrameworks-RecordMode'
  end

  opts.on('--ci', 'CI mode: use any available simulator matching the device model') do
    ci_mode = true
  end
end.parse!

devices_json = JSON.parse(`xcrun simctl list devices available -j`)['devices']
os_version = nil

devices_json.each do |runtime, device_list|
  next unless runtime.include?('iOS')
  device_list.each do |d|
    if d['name'] == DEVICE_MODEL
      os_version = runtime.scan(/iOS[- ](\d+[.-]\d+)/).flatten.first&.tr('-', '.')
      break
    end
  end
  break if os_version
end

abort "Could not find an available #{DEVICE_MODEL} simulator" if os_version.nil?

system('./ci_scripts/test.rb', '--only-snapshot-tests',
       '--scheme', scheme,
       '--device', DEVICE_MODEL,
       '--version', os_version)
exit($?.exitstatus || 1)
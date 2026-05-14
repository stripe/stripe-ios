#!/usr/bin/env ruby

SCRIPT_DIR = __dir__
abort 'Unable to find SCRIPT_DIR' if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?

ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
abort 'Unable to find ROOT_DIR' if ROOT_DIR.nil? || ROOT_DIR.empty?

Dir.chdir(ROOT_DIR)

DEVICE_MODEL = 'iPhone 12 mini'
OS_VERSION = '16.4'

system('./ci_scripts/test.rb', '--only-snapshot-tests',
       '--scheme', 'AllStripeFrameworks',
       '--device', DEVICE_MODEL,
       '--version', OS_VERSION)
exit($?.exitstatus || 1)

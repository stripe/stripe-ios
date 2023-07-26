#!/usr/bin/env ruby

require_relative 'common'

run_command('rm -f .package.resolved', false)
run_command('find Stripe.xcworkspace -type f ! -name "Package.resolved" -exec rm {} +', false)
run_command('find Stripe* -type d -name "*.xcodeproj" -exec rm -r {} +', false)
run_command('find Example -type d -name "*.xcodeproj" -exec rm -r {} +', false)
run_command('find Testers -type d -name "*.xcodeproj" -exec rm -r {} +', false)

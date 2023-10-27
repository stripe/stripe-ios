#!/usr/bin/env ruby

require_relative 'common'

# If we delete the project while Xcode is running, it will corrupt the Package.resolved
run_command('killall -9 Xcode', false)
run_command('rm -f .package.resolved', false)
run_command('find Stripe.xcworkspace -type f ! -name "Package.resolved" -exec rm {} +', false)
run_command('find Stripe* -type d -name "*.xcodeproj" -exec rm -r {} +', false)
run_command('find Example -type d -name "*.xcodeproj" -exec rm -r {} +', false)
run_command('find Testers -type d -name "*.xcodeproj" -exec rm -r {} +', false)

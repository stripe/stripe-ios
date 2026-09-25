#!/usr/bin/env ruby
# frozen_string_literal: true

# Determines whether Financial Connections stability tests are relevant to the
# current change and exports the result for later Bitrise steps.

RELEVANT_PATHS = [
  'Example/FinancialConnections Example/',
  'StripeFinancialConnections/',
  'StripeFinancialConnectionsLite/',
  'StripeCore/',
  'StripeUICore/',
  'StripePayments/',
  'StripePaymentsUI/',
  'StripePaymentSheet/',
  'StripeApplePay/',
  'Stripe3DS2/',
  'BuildConfigurations/',
  'ci_scripts/',
  'fastlane/',
  'Stripe.xcworkspace/',
  'bitrise.yml',
  'Gemfile',
  'Gemfile.lock',
  'Package.swift'
].freeze

def relevant?(path)
  RELEVANT_PATHS.any? { |relevant_path| path == relevant_path || path.start_with?(relevant_path) } ||
    path.end_with?('.podspec')
end

def changed_files
  return nil if ENV['BITRISE_PULL_REQUEST'].to_s.empty?

  output = `git diff --name-only --diff-filter=ACDMRTUXB origin/master HEAD 2>/dev/null`
  return nil unless $?.success?

  output.lines(chomp: true)
end

def main
  files = changed_files
  should_run = files.nil? || files.empty? || files.any? { |path| relevant?(path) }
  value = should_run ? 'true' : 'false'
  pull_request = ENV['BITRISE_PULL_REQUEST'].to_s
  notify_value = pull_request.empty? ? 'true' : 'false'

  if files
    puts "Changed files:\n  #{files.join("\n  ")}"
  elsif pull_request.empty?
    puts 'Not a pull request; this may be a master push or a scheduled/manual run. Running FC stability tests.'
  else
    puts 'Could not determine the pull request diff; running FC stability tests as a safety fallback.'
  end
  puts "RUN_FC_STABILITY_TESTS=#{value}"
  puts "NOTIFY_FC_STABILITY_TESTS=#{notify_value}"

  if system('which envman > /dev/null 2>&1')
    abort 'Failed to export RUN_FC_STABILITY_TESTS' unless system('envman', 'add', '--key', 'RUN_FC_STABILITY_TESTS', '--value', value)
    abort 'Failed to export NOTIFY_FC_STABILITY_TESTS' unless system('envman', 'add', '--key', 'NOTIFY_FC_STABILITY_TESTS', '--value', notify_value)
  else
    ENV['RUN_FC_STABILITY_TESTS'] = value
    ENV['NOTIFY_FC_STABILITY_TESTS'] = notify_value
  end
end

main if __FILE__ == $PROGRAM_NAME

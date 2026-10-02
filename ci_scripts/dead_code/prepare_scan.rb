# frozen_string_literal: true

require 'digest'
require 'json'
require 'open3'
require 'yaml'
require_relative '../ci_change_scope'

def capture!(*command)
  output, status = Open3.capture2(*command)
  abort "Command failed: #{command.join(' ')}" unless status.success?

  output
end

def output(name, value)
  File.open(ENV.fetch('GITHUB_OUTPUT'), 'a') { |file| file.puts "#{name}=#{value}" }
end

if ARGV == ['fingerprint']
  files = ['.periphery.yml', '.github/workflows/find-dead-code.yml', 'ci_scripts/ci_change_scope.rb'] + Dir['ci_scripts/dead_code/*.rb'].sort
  recipe = Digest::SHA256.new
  files.each { |path| recipe.update(path).update("\0").update(File.binread(path)).update("\0") }
  toolchain = [capture!('xcodebuild', '-version'), capture!('xcrun', 'swift', '-version'),
               capture!('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-build-version')].join("\n")
  output('recipe', recipe.hexdigest)
  output('toolchain', Digest::SHA256.hexdigest(toolchain))
  exit
end

event = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
source = capture!('git', 'rev-parse', 'HEAD').strip
abort 'Checkout does not match the event commit' unless source == ENV.fetch('GITHUB_SHA')

pull_request = event['pull_request']
baseline = pull_request ? pull_request.fetch('base').fetch('sha') : event.fetch('before')
abort 'Expected an immutable base commit' unless baseline.match?(/\A[0-9a-f]{40}\z/)

paths = nil
unless baseline == '0' * 40
  fetched = system('git', 'fetch', '--no-tags', '--depth=1', 'origin', baseline)
  abort 'Could not fetch the PR base commit' if pull_request && !fetched

  paths = capture!('git', 'diff', '--name-only', '--no-renames', '-z', baseline, source).split("\0") if fetched
end

# This exclusion is valid only for the framework-only scan that ignores tests.
config = YAML.safe_load(File.read('.periphery.yml'))
known_scope = config['exclude_tests'] == true && config['schemes'] == ['AllStripeFrameworks']
required = paths.nil? || !known_scope || CIChangeScope.scan_required?(paths)
puts(required ? 'SDK or scan inputs changed; checking dead code.' : 'Only test, example, or documentation files changed; no SDK scan needed.')
output('required', required)
output('source', source)
output('baseline', baseline) if pull_request

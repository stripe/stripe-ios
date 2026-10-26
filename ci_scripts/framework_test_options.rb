# frozen_string_literal: true

require 'shellwords'
require_relative 'snapshot_test_selection'

# Only pipelines with the required snapshot workflow delegate these classes.
# Standalone framework workflows retain all tests, including snapshots.
if ENV['CI_SNAPSHOTS_IN_DEDICATED_WORKFLOW'] == 'true'
  root = File.expand_path('..', __dir__)
  puts SnapshotTestSelection.discover(root).map { |test| "-skip-testing:#{test}" }.shelljoin
end

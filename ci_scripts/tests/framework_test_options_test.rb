# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require 'shellwords'
require_relative '../snapshot_test_selection'

class FrameworkTestOptionsTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)
  SCRIPT = File.join(ROOT, 'ci_scripts/framework_test_options.rb')

  def options(enabled)
    output, status = Open3.capture2(
      { 'CI_SNAPSHOTS_IN_DEDICATED_WORKFLOW' => enabled }, RbConfig.ruby, SCRIPT
    )
    assert status.success?
    output.shellsplit
  end

  def test_standalone_workflows_retain_snapshots
    assert_empty options(nil)
    assert_empty options('false')
  end

  def test_dedicated_workflow_exclusions_match_recorded_classes
    tests = SnapshotTestSelection.discover(ROOT)
    refute_empty tests
    assert_equal tests.map { |test| "-skip-testing:#{test}" }, options('true')
  end
end

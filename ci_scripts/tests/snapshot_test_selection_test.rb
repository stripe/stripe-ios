# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../snapshot_test_selection'

class SnapshotTestSelectionTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)

  def setup
    @tests = SnapshotTestSelection.discover(ROOT)
    @graph = SnapshotTestSelection.graph(ROOT)
  end

  def test_paymentsheet_changes_include_legacy_tests_that_link_paymentsheet
    selected = SnapshotTestSelection.affected(@tests, ['StripePaymentSheet/StripePaymentSheet/Component.swift'], @graph)
    assert_equal %w[StripePaymentSheetTests StripeiOSTests], selected.map { |test| test.split('/').first }.uniq.sort
  end

  def test_shared_test_utility_changes_select_consuming_snapshot_targets
    selected = SnapshotTestSelection.affected(@tests, ['StripeCore/StripeCoreTestUtils/STPSnapshotTestCase.swift'], @graph)
    %w[StripeIdentityTests StripePaymentSheetTests StripePaymentsUITests StripeUICoreTests StripeiOSTests].each do |target|
      assert selected.any? { |test| test.start_with?(target + '/') }, target
    end
  end

  def test_changes_to_snapshot_tests_themselves_run_their_module
    selected = SnapshotTestSelection.affected(@tests, ['StripeIdentity/StripeIdentityTests/Snapshot/NewSnapshotTest.swift'], @graph)
    refute_empty selected
    assert selected.all? { |test| test.start_with?('StripeIdentityTests/') }
  end

  def test_modules_without_snapshots_need_no_recording
    assert_empty SnapshotTestSelection.affected(@tests, ['StripeFinancialConnections/StripeFinancialConnections/API.swift'], @graph)
  end

  def test_unknown_shared_inputs_record_every_snapshot
    %w[Package.swift bitrise.yml BuildConfigurations/Shared.xcconfig Tests/ReferenceImages_64/example.png].each do |file|
      assert_equal @tests, SnapshotTestSelection.affected(@tests, [file], @graph)
    end
  end

  def test_unknown_snapshot_target_records_every_snapshot
    tests = @tests + ['NewTests/NewSnapshotTests']
    assert_equal tests, SnapshotTestSelection.affected(tests, ['StripeIdentity/File.swift'], @graph)
  end

  def test_renames_select_both_module_dependencies
    selected = SnapshotTestSelection.affected(@tests, ['StripeIdentity/Old.swift', 'StripePaymentSheet/New.swift'], @graph)
    assert_equal %w[StripeIdentityTests StripePaymentSheetTests StripeiOSTests], selected.map { |test| test.split('/').first }.uniq.sort
  end

  def test_generated_scheme_builds_selected_tests_and_keeps_annotations
    Dir.mktmpdir('snapshot-selection-', File.expand_path('~/stripe')) do |directory|
      schemes = File.join(directory, 'Stripe.xcworkspace/xcshareddata/xcschemes')
      FileUtils.mkdir_p(schemes)
      FileUtils.mkdir_p(File.join(directory, 'Stripe'))
      FileUtils.cp(File.join(ROOT, 'Stripe.xcworkspace/xcshareddata/xcschemes/AllStripeFrameworks.xcscheme'), schemes)
      plan = JSON.parse(File.read(File.join(ROOT, 'Stripe/AllStripeFrameworks-iOS26.xctestplan')))
      original = Marshal.load(Marshal.dump(plan))
      test = 'StripePaymentSheetTests/LinkHintMessageViewSnapshotTests'
      generated = nil
      SnapshotTestSelection.with_scheme(directory, [test], plan: plan) do |scheme|
        generated = File.join(schemes, scheme + '.xcscheme')
        document = REXML::Document.new(File.read(generated))
        references = document.get_elements('Scheme/BuildAction/BuildActionEntries/BuildActionEntry/BuildableReference')
        assert_equal ['StripePaymentSheetTests'], references.map { |reference| reference.attributes['BlueprintName'] }
        assert_equal 'StripePaymentSheetTests', document.elements['Scheme/TestAction/MacroExpansion/BuildableReference'].attributes['BlueprintName']
        environment = document.elements['Scheme/TestAction/EnvironmentVariables/EnvironmentVariable']
        assert_equal 'FB_REFERENCE_IMAGE_DIR', environment.attributes['key']
        assert_equal '$(SOURCE_ROOT)/../Tests/ReferenceImages', environment.attributes['value']
        selected = JSON.parse(File.read(File.join(directory, "Stripe/#{scheme}.xctestplan")))
        assert_equal ['StripePaymentSheetTests'], selected.fetch('testTargets').map { |target| target.fetch('target').fetch('name') }
        assert_equal 'StripePaymentSheetTests', selected.fetch('defaultOptions').fetch('targetForVariableExpansion').fetch('name')
        methods = selected.fetch('testTargets').first.fetch('selectedTests')
        refute_empty methods
        assert methods.all? { |method| method.start_with?('LinkHintMessageViewSnapshotTests/') }
        assert_equal original, plan, 'Scheme generation must not mutate the source test plan'
      end
      refute File.exist?(generated)
      assert_empty Dir.glob(File.join(directory, 'Stripe/*.xctestplan'))
    end
  end
end

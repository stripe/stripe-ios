# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../snapshot_test_selection'
require_relative '../generate_ios26_testplan'

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

  def test_generated_ios26_plan_retains_every_annotated_method
    with_workspace do |directory|
      plan_path = File.join(directory, 'Stripe/AllStripeFrameworks-iOS26.xctestplan')
      FileUtils.cp(File.join(ROOT, 'Stripe/AllStripeFrameworks-iOS26.xctestplan'), plan_path)
      generator = IOS26TestPlanGeneratorV2.new
      generator.instance_variable_set(:@test_plan_file, plan_path)
      capture_io { Dir.chdir(ROOT) { generator.generate } }
      plan = JSON.parse(File.read(plan_path))
      classes = SnapshotTestSelection.classes_in_plan(plan)
      assert_includes classes, 'StripeiOSTests/ConfirmButtonTests'
      # An unknown CI input must retain every generated annotation.
      selected = SnapshotTestSelection.affected(classes, ['bitrise.yml'], @graph)
      SnapshotTestSelection.with_scheme(directory, selected, plan: plan) do |scheme|
        generated = JSON.parse(File.read(File.join(directory, "Stripe/#{scheme}.xctestplan")))
        methods = lambda do |value|
          value.fetch('testTargets').each_with_object({}) do |target, result|
            tests = target.fetch('selectedTests')
            result[target.fetch('target').fetch('name')] = tests unless tests.empty?
          end
        end
        assert_equal methods.call(plan), methods.call(generated)
        assert_includes methods.call(generated).fetch('StripeiOSTests'),
                        'ConfirmButtonTests/testBuyButtonShouldAutomaticallyAdjustItsForegroundColor()'
      end
    end
  end

  def test_annotation_only_target_is_selected_without_snapshot_classes
    with_workspace do |directory|
      plan = JSON.parse(File.read(File.join(ROOT, 'Stripe/AllStripeFrameworks-iOS26.xctestplan')))
      plan.fetch('testTargets').select! { |target| target.fetch('target').fetch('name') == 'StripeCoreTests' }
      methods = ['EnvironmentTests/testAnnotatedBehavior()', 'EnvironmentTests/testOtherAnnotatedBehavior()']
      plan.fetch('testTargets').first['selectedTests'] = methods
      refute @tests.any? { |test| test.start_with?('StripeCoreTests/') }
      selected = SnapshotTestSelection.affected(SnapshotTestSelection.classes_in_plan(plan), ['StripeCore/StripeCore/Environment.swift'], @graph)
      assert_equal ['StripeCoreTests/EnvironmentTests'], selected
      SnapshotTestSelection.with_scheme(directory, selected, plan: plan) do |scheme|
        generated = JSON.parse(File.read(File.join(directory, "Stripe/#{scheme}.xctestplan")))
        assert_equal methods, generated.fetch('testTargets').first.fetch('selectedTests')
      end
    end
  end

  def test_generated_scheme_builds_selected_tests_and_keeps_annotations
    Dir.mktmpdir('snapshot-selection-') do |directory|
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

  private

  def with_workspace
    Dir.mktmpdir('snapshot-selection-') do |directory|
      schemes = File.join(directory, 'Stripe.xcworkspace/xcshareddata/xcschemes')
      FileUtils.mkdir_p(schemes)
      FileUtils.mkdir_p(File.join(directory, 'Stripe'))
      FileUtils.cp(File.join(ROOT, 'Stripe.xcworkspace/xcshareddata/xcschemes/AllStripeFrameworks.xcscheme'), schemes)
      yield directory
    end
  end
end

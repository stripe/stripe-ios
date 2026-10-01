#!/usr/bin/ruby

require 'minitest/autorun'
require 'tmpdir'
require_relative '../check_paymentsheet_test_sharding'

class PaymentSheetTestShardingTest < Minitest::Test
  def inventory
    { 'UI' => { 'LargeTests' => %w[testFirst testSecond], 'SmallTests' => %w[testOnly] } }
  end

  def plan(selected, **options)
    { 'testTargets' => [{ 'target' => { 'name' => 'UI' }, 'selectedTests' => selected }.merge(options.transform_keys(&:to_s))] }
  end

  def test_split_class_keeps_each_method_in_one_shard
    plans = [plan(['LargeTests/testFirst()', 'SmallTests']), plan(['LargeTests/testSecond()'])]
    assert_empty PaymentSheetTestSharding.check(plans, inventory)
  end

  def test_new_method_in_split_class_is_not_silently_omitted
    plans = [plan(['LargeTests/testFirst()', 'SmallTests'])]
    assert_equal ['UI/LargeTests/testSecond runs in 0 shards; expected exactly one.'],
                 PaymentSheetTestSharding.check(plans, inventory)
  end

  def test_class_and_method_in_different_shards_are_detected_as_duplicates
    plans = [plan(['LargeTests', 'SmallTests']), plan(['LargeTests/testFirst()'])]
    assert_equal ['UI/LargeTests/testFirst runs in 2 shards; expected exactly one.'],
                 PaymentSheetTestSharding.check(plans, inventory)
  end

  def test_disabled_target_does_not_count_as_coverage
    plans = [plan(['LargeTests', 'SmallTests'], enabled: false)]
    assert_equal 3, PaymentSheetTestSharding.check(plans, inventory).length
  end

  def test_skipped_method_does_not_count_as_coverage
    plans = [plan(['LargeTests', 'SmallTests'], skippedTests: ['LargeTests/testSecond()'])]
    assert_equal ['UI/LargeTests/testSecond runs in 0 shards; expected exactly one.'],
                 PaymentSheetTestSharding.check(plans, inventory)
  end

  def test_stale_method_selection_fails
    assert_raises(RuntimeError) do
      PaymentSheetTestSharding.check([plan(['LargeTests/testRemoved()'])], inventory)
    end
  end

  def test_inventory_ignores_comments_and_includes_inherited_tests
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, 'Base.swift'), <<~SWIFT)
        class BaseCase: XCTestCase {
            func testInherited() {}
            /*
            func testDisabled() {}
            */
            // func testCommented() {}
        }
      SWIFT
      File.write(File.join(directory, 'Child.swift'), <<~SWIFT)
        final class ChildTests: BaseCase {
            func testChild() throws {}
            private func testHelper(value: Bool) {}
        }
      SWIFT
      assert_equal({ 'BaseCase' => ['testInherited'], 'ChildTests' => %w[testChild testInherited] },
                   PaymentSheetTestSharding.test_classes(directory))
    end
  end

  def test_repository_plans_cover_all_current_tests
    plans = Dir.glob(File.join(PaymentSheetTestSharding::EXAMPLE, '*-Shard*.xctestplan')).map do |path|
      JSON.parse(File.read(path))
    end
    assert_equal 4, plans.length
    assert_empty PaymentSheetTestSharding.check(plans, PaymentSheetTestSharding.inventory)
  end

  def test_annotated_and_modified_methods_cannot_be_silently_omitted
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, 'Annotated.swift'), <<~SWIFT)
        @MainActor final class LargeTests: XCTestCase {
            @MainActor func testAnnotated() {}
            public func testPublic() {}
            override func testOverride() {}
        }
      SWIFT
      classes = PaymentSheetTestSharding.test_classes(directory)
      assert_equal %w[testAnnotated testPublic testOverride], classes.fetch('LargeTests')
      errors = PaymentSheetTestSharding.check([plan(['LargeTests/testPublic()'])], { 'UI' => classes })
      assert_equal 2, errors.length
      assert errors.any? { |error| error.include?('testAnnotated runs in 0 shards') }
    end
  end

  def test_unrecognized_test_declaration_fails_visibly
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, 'Unrecognized.swift'), <<~SWIFT)
        class LargeTests: XCTestCase {
            unexpectedModifier func testNew() {}
        }
      SWIFT
      error = assert_raises(RuntimeError) { PaymentSheetTestSharding.test_classes(directory) }
      assert_match 'Unrecognized test declaration', error.message
    end
  end
end

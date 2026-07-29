require 'minitest/autorun'
require_relative 'diff_public_interface'

class TestNonApiNoiseLine < Minitest::Test
  # Generated swift-interface metadata comments are noise.
  def test_swift_metadata_comment
    assert non_api_noise_line?('-// swift-compiler-version: Apple Swift version 5.10')
    assert non_api_noise_line?('+// swift-module-flags: -module-name StripePaymentSheet')
  end

  # Ordinary imports are noise whether added or removed.
  def test_plain_import_removed
    assert non_api_noise_line?('-import WebKit')
    assert non_api_noise_line?('+import Foundation')
  end

  def test_preconcurrency_import_removed
    assert non_api_noise_line?('-@preconcurrency import WebKit')
    assert non_api_noise_line?('+@preconcurrency import UIKit')
  end

  # @_exported import is public API surface — must NOT be filtered.
  def test_exported_import_kept
    refute non_api_noise_line?('-@_exported import StripeFinancialConnectionsLite')
    refute non_api_noise_line?('+@_exported import StripeCore')
  end

  # Real public declarations must not be filtered.
  def test_public_declaration_kept
    refute non_api_noise_line?('-public func doSomething()')
    refute non_api_noise_line?('+public class MyClass {}')
  end
end

class TestFilterNonApiLines < Minitest::Test
  # Regression shape: only noise lines → empty after filtering.
  def test_fc_lite_regression_shape
    diff = [
      '-// swift-compiler-version: Apple Swift version 5.10',
      '-// swift-module-flags: -module-name StripePaymentSheet',
      '-@preconcurrency import WebKit',
      '+import StripeFinancialConnectionsLite'
    ]
    result = filter_non_api_lines(diff)
    assert_empty result
  end

  # No non-additive changes after filtering means severity should not be public.
  def test_filtered_noise_has_no_non_additive_changes
    diff = [
      '-// swift-compiler-version: Apple Swift version 5.10',
      '-@preconcurrency import WebKit',
      '+import NewModule'
    ]
    filtered = filter_non_api_lines(diff)
    refute has_non_additive_changes?(filtered)
  end

  # @_exported import removal is retained and counts as non-additive.
  def test_exported_import_removal_retained
    diff = [
      '-@_exported import StripeFinancialConnectionsLite',
      '-// swift-module-flags: -module-name StripePaymentSheet',
      '-@preconcurrency import WebKit'
    ]
    filtered = filter_non_api_lines(diff)
    assert_equal ['-@_exported import StripeFinancialConnectionsLite'], filtered
    assert has_non_additive_changes?(filtered)
  end

  # A removed public declaration is retained and counts as non-additive.
  def test_public_declaration_removal_retained
    diff = [
      '-public func removedMethod()',
      '-@preconcurrency import WebKit',
      '-// swift-compiler-version: Apple Swift version 5.10'
    ]
    filtered = filter_non_api_lines(diff)
    assert_equal ['-public func removedMethod()'], filtered
    assert has_non_additive_changes?(filtered)
  end

  # Mixed diff: noise removed + real declaration removed → only declaration survives.
  def test_mixed_diff_retains_only_real_declarations
    diff = [
      '-// swift-module-flags: -module-name Foo',
      '-import UIKit',
      '-@preconcurrency import WebKit',
      '-public class RemovedClass {}',
      '+import NewDep'
    ]
    filtered = filter_non_api_lines(diff)
    assert_equal ['-public class RemovedClass {}'], filtered
  end
end

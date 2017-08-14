require 'test/unit'

require_relative '../rules/property_rule'

class PropertyRuleTest < Test::Unit::TestCase
  def test_apply_property_spacing_rule_autocorrect_compact
    # Should autocorrect property spacing (compact style)
    line = '@property(nonatomic,strong,readwrite)NSString *string; // comment'
    expected = '@property (nonatomic, strong, readwrite) NSString *string; // comment'
    result = Rules::PropertyRule.apply_property_spacing_rule('file_name', [line])
    assert_equal([expected], result)
  end

  def test_apply_property_spacing_rule_autocorrect_expanded
    # Should autocorrect property spacing (expanded style)
    line = '@property    ( nonatomic,   strong  , readwrite  )    NSString *string; // comment'
    expected = '@property (nonatomic, strong, readwrite) NSString *string; // comment'
    result = Rules::PropertyRule.apply_property_spacing_rule('file_name', [line])
    assert_equal([expected], result)
  end

  def test_apply_property_attributes_ordering_rule_garbage
    # Should throw on unrecognized property attribute
    line = '@property (garbage) NSString *string;'
    assert_raise do
      Rules::PropertyRule.apply_property_attributes_ordering_rule('file_name', [line])
    end
  end

  def test_apply_property_attributes_ordering_rule_autocorrect
    # Should autocorrect property attribute ordering
    line = '@property (nonatomic, readwrite, strong) NSString *string;'
    expected = '@property (nonatomic, strong, readwrite) NSString *string;'
    result = Rules::PropertyRule.apply_property_attributes_ordering_rule('file_name', [line])
    assert_equal([expected], result)
  end

  def test_apply_property_attributes_ordering_rule_autocorrect_comment
    # Should autocorrect property attribute ordering (line ends with comment)
    line = '@property (nonatomic, readwrite, strong) NSString *string; // comment'
    expected = '@property (nonatomic, strong, readwrite) NSString *string; // comment'
    result = Rules::PropertyRule.apply_property_attributes_ordering_rule('file_name', [line])
    assert_equal([expected], result)
  end

  def test_apply_property_attributes_ordering_rule_non_property
    # Should do nothing for non property line
    line = 'NSString *string;'
    expected = 'NSString *string;'
    result = Rules::PropertyRule.apply_property_attributes_ordering_rule('file_name', [line])
    assert_equal([expected], result)
  end
end

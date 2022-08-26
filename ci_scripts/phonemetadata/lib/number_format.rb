# frozen_string_literal: true

# :nodoc:
module PhoneMetadata
  # :nodoc:
  class NumberFormat
    EXPANSION_TEMPLATE = '99999999999999999999'

    def initialize(node, trunk_prefix:)
      @node = node
      @trunk_prefix = trunk_prefix
    end

    def pattern
      @pattern ||= Regexp.new(@node.attribute('pattern').text)
    end

    def trunk_prefix_formatting_rule
      @node.attribute('nationalPrefixFormattingRule')&.text&.gsub('$', '\\')
    end

    def national_format
      return nil if trunk_prefix_formatting_rule.nil?

      # Check that the national format contains the national prefix
      return nil unless trunk_prefix_formatting_rule.include?('\NP')

      # Check if national format can be created at runtime.
      return nil if trunk_prefix_formatting_rule == '\NP\FG'

      formatting_rule = trunk_prefix_formatting_rule

      unless @trunk_prefix.nil?
        formatting_rule = formatting_rule.gsub(
          '\NP', '#' * @trunk_prefix.length
        )
      end

      format.gsub('\1', formatting_rule).gsub('FG', '1')
    end

    def leading_digits
      @node.xpath('leadingDigits').map { |t| t.text.gsub(/\s+/, '') }
    end

    def format
      @node.xpath('format').text.gsub('$', '\\')
    end

    def trunk_prefix_optional_when_formatting?
      @node.attribute('nationalPrefixOptionalWhenFormatting')&.text == 'true'
    end

    def expanded
      tmp = EXPANSION_TEMPLATE
      tmp.match(pattern)
         .to_s
         .gsub(pattern, format)
         .gsub(/\d/, '#')
    end

    def expanded_national_template
      return nil if national_format.nil?

      tmp = EXPANSION_TEMPLATE
      tmp.match(pattern)
         .to_s
         .gsub(pattern, national_format)
         .gsub(/\d/, '#')
    end

    def matchers
      leading_digits.map do |ld|
        "^#{ld}"
      end
    end

    # Whether or not the format is valid for "As You Type Formatting".
    # This currently filters out some legacy number formats from MX.
    def valid_for_aytf?
      # Get a list of capture groups. i.e.: [1, 2, 3]
      groups = format.scan(/\\(\d)/).to_a.flatten.map(&:to_i)
      # Check whether the array starts with 1, are incremental, and
      # are arranged in ascending order.
      expected = (1..groups.count).to_a
      groups == expected
    end

    def length
      expanded.scan(/#/).count
    end

    def validate!
      # Verify that the matchers are valid regexes.
      matchers.each { |matcher| Regexp.new(matcher) }
    end

    def to_dict
      validate!
      Utils.strip_nil_values(
        template: expanded,
        national_template: expanded_national_template,
        # trunk_prefix_optional: trunk_prefix_optional_when_formatting?,
        matchers: matchers
      )
    end
  end
end

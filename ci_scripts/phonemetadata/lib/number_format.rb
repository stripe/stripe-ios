# frozen_string_literal: true

require_relative 'utils'
require_relative 'expanded_format'

# :nodoc:
module PhoneMetadata
  # :nodoc:
  class NumberFormat
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

    def format
      @node.xpath('format').text.gsub('$', '\\')
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

    def matchers
      @node.xpath('leadingDigits')
           .map { |ld| ld.text.gsub(/\s+/, '') }
           .map { |ld| "^#{ld}" }
    end

    # Whether or not the format is valid for "As You Type Formatting".
    # This currently filters out some legacy number formats from MX.
    def valid_for_aytf?
      # Get a list of capture groups. i.e.: [1, 2, 3]
      groups = format.scan(/\\(\d)/).to_a.flatten.map(&:to_i)
      # Check whether the array starts with 1, are sequential, and
      # are arranged in ascending order.
      expected = (1..groups.count).to_a
      groups == expected
    end

    def variable_length_in_middle?
      pattern_str = @node.attribute('pattern').text
      match = VARIABLE_DIGIT_GROUP_PATTERN.match(pattern_str)

      return false if match.nil?

      match.end(0) != pattern_str.length
    end

    # rubocop:disable Metrics/MethodLength
    def expand(lengths)
      result = []

      lengths.each do |l|
        template = Utils.expand_format(format, pattern: pattern, n_digits: l)
        next if template.nil?

        result << ExpandedFormat.new(
          template: template,
          national_template: Utils.expand_format(
            national_format, pattern: pattern, n_digits: l
          ),
          matchers: matchers
        )
      end

      ExpandedFormat.coalesce(result)
    end
    # rubocop:enable Metrics/MethodLength
  end
end

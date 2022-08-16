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
      rule = @node.attribute('nationalPrefixFormattingRule')&.text
      return nil if rule.nil?

      rule.gsub('$', '\\')
    end

    def carrier_code_formatting_rule
      rule = @node.attribute('carrierCodeFormattingRule')&.text
      return nil if rule.nil?

      rule.gsub('$', '\\')
    end

    def national_format
      return nil if trunk_prefix_formatting_rule.nil?

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

    def trunk_prefix_optional_when_formatting
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
        if PhoneMetadata::Utils.numeric?(ld)
          "^#{ld}"
        else
          "^(#{ld})"
        end
      end
    end

    def length
      expanded.scan(/#/).count
    end

    def validate!
      matchers.each { |matcher| Regexp.new(matcher) }
    end

    def trunk_prefix_rule
      if requires_trunk_prefix?
        'required'
      elsif trunk_prefix_disallowed?
        'disallowed'
      else
        'allowed'
      end
    end

    def trunk_prefix_disallowed?
      trunk_prefix_has_first_group_only? &&
        !trunk_prefix_optional_when_formatting &&
        carrier_code_formatting_rule.nil?
    end

    def requires_trunk_prefix?
      !trunk_prefix_has_first_group_only? &&
        !trunk_prefix_optional_when_formatting
    end

    def trunk_prefix_has_first_group_only?
      return false if trunk_prefix_formatting_rule.nil?

      trunk_prefix_formatting_rule.match(/^\(?\\1\)?$/)
    end

    def to_dict
      validate!
      {
        template: expanded,
        national_template: expanded_national_template,
        trunk_prefix_rule: trunk_prefix_rule,
        matchers: matchers
      }.reject { |_, v| v.nil? }
    end
  end
end

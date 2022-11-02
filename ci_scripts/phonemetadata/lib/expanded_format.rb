# frozen_string_literal: true

require_relative 'utils'

# :nodoc:
module PhoneMetadata
  # :nodoc:
  class ExpandedFormat
    attr_reader :template, :national_template, :matchers, :optional_trunk_prefix

    def initialize(
      template:,
      national_template:,
      matchers:
    )
      @template = template
      @national_template = national_template
      @matchers = matchers
    end

    def validate!
      # Verify that the matchers are valid regexes.
      matchers.each { |matcher| Regexp.new(matcher) }
    end

    def to_dict
      Utils.strip_nil_values(
        template: template,
        national_template: national_template,
        matchers: matchers
      )
    end

    def self.coalesce(expanded_formats)
      result = []

      expanded_formats.reverse.each do |format|
        if result.empty?
          result << format
        elsif !result.last.template.start_with?(format.template)
          result << format
        end
      end

      result.reverse
    end
  end
end

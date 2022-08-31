# frozen_string_literal: true

require_relative 'utils'
require_relative 'number_format'

# :nodoc:
module PhoneMetadata
  # :nodoc:
  class Territory
    def initialize(node)
      @node = node
    end

    # Returns the ID (ISO country code) of the territory.
    def id
      @node.attribute('id').text
    end

    # Country calling code
    def code
      @node.attribute('countryCode').text
    end

    # True if this territory is the main territory for its calling code.
    #
    # Some countries share calling codes, but only the main one has the
    # formatting rules that others should inherit.
    def main_for_code?
      @node.attribute('mainCountryForCode')&.text == 'true'
    end

    def formats
      expanded_formats
    end

    # National (trunk) prefix.
    def trunk_prefix
      @node.attribute('nationalPrefix')&.text
    end

    def lengths
      lengths = []

      %w[fixedLine mobile voip].each do |tag|
        length_spec = @node.xpath("#{tag}/possibleLengths")
                           .attribute('national')&.text
        next if length_spec.nil?

        length_spec.split(',').each do |len|
          lengths << Utils.parse_range(len)
        end
      end

      lengths.flatten.uniq.sort
    end

    def validate!
      expanded_formats.each(&:validate!)
    end

    def to_dict(override_formats:)
      Utils.strip_nil_values(
        region: id,
        code: "+#{code}",
        trunk_prefix: trunk_prefix,
        lengths: lengths,
        formats: override_formats.map(&:to_dict)
      )
    end

    def <=>(other)
      # Sort by code, being main for a code, and them by ID.
      # Because we are sorting in ascending order, main territories have a
      # value of `0` so they bubble up to the top.
      a = [code, (main_for_code? ? 0 : 1), id]
      b = [other.code, (other.main_for_code? ? 0 : 1), other.id]
      a <=> b
    end

    private

    def expanded_formats
      @expanded_formats ||= begin
        @node.xpath('availableFormats/numberFormat')
             .map { |f| NumberFormat.new(f, trunk_prefix: trunk_prefix) }
             .filter(&:valid_for_aytf?)
             .map { |f| f.expand(lengths) }
             .flatten
      end
    end
  end
end

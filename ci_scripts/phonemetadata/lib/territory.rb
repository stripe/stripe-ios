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
      @node.xpath('availableFormats/numberFormat')
           .map { |f| NumberFormat.new(f, trunk_prefix: trunk_prefix) }
    end

    def valid_formats
      if complex?
        []
      else
        supported_formats
      end
    end

    # A narrowed down list of formats that we support in the SDK.
    def supported_formats
      formats.select { |f| lengths.include?(f.length) && !f.complex? }
    end

    def complex?
      supported_formats
        .map(&:trunk_prefix_optional_when_formatting?)
        .uniq.size > 1
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

    def to_dict(override_formats:)
      Utils.strip_nil_values(
        region: id,
        prefix: "+#{code}",
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
  end
end

# frozen_string_literal: true

require 'nokogiri'
require_relative 'territory'

# :nodoc:
module PhoneMetadata
  # :nodoc:
  class Metadata
    UNSUPPORTED_TERRITORIES = [
      '001', # Non-geographic entity
      'CU',  # Cuba
      'IR',  # Iran
      'KP',  # Democratic People's Republic of Korea (DPRK)
      'SD',  # Sudan
      'SY',  # Syria
      'AS',  # American Samoa - United States
      'CC',  # Cocos (Keeling) Islands - Australia
      'CX',  # Christmas Island - Australia
      'FM',  # Micronesia
      'MH',  # Marshall Islands
      'MP',  # Northern Mariana Islands
      'NF',  # Norfolk Island - Australia
      'PW',  # Palau
      'VI'   # U.S. Virgin Islands - United States
    ].freeze

    def initialize(node)
      @node = node
      @territory_cache = {}
    end

    def self.load(path)
      xml_doc = File.open(path) { |f| Nokogiri::XML(f) }
      Metadata.new(xml_doc)
    end

    def territories
      @territories ||= @node.xpath('//territories/territory')
                            .map { |node| Territory.new(node) }
                            .reject { |t| UNSUPPORTED_TERRITORIES.include?(t.id) }
    end

    def territory_for_code(code)
      @territory_cache[code] = begin
        territories.find { |t| t.code == code && t.main_for_code? } ||
          territories.find { |t| t.code == code }
      end
    end

    def get(fallback: false)
      if fallback
        fallback_data
      else
        to_dict
      end
    end

    def to_dict
      result = territories.sort
      result.map do |territory|
        territory.to_dict(
          override_formats: territory_for_code(territory.code).valid_formats
        )
      end
    end

    def fallback_data
      territories.sort.map do |territory|
        [territory.id, territory.code.to_i, territory.trunk_prefix]
      end
    end
  end
end

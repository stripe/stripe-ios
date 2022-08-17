# frozen_string_literal: true

require 'nokogiri'
require_relative 'territory'

# :nodoc:
module PhoneMetadata
  # :nodoc:
  class Metadata
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
                            .reject { |t| t.id == '001' }
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
      data = {}
      territories.sort.each do |territory|
        data[territory.id] = [territory.code.to_i, territory.trunk_prefix]
      end
      data
    end
  end
end

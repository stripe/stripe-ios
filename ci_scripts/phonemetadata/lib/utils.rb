# frozen_string_literal: true

require 'lzfse'

# :nodoc:
module PhoneMetadata
  # Utility functions.
  module Utils
    def self.numeric?(str)
      !Float(str).nil?
    rescue ArgumentError
      false
    end

    def self.parse_range(str)
      return str.to_i if numeric?(str)

      matches = /\[(\d+)-(\d+)\]/.match(str)
      (matches[1].to_i..matches[2].to_i).to_a
    end

    def self.write_lzfse_file(path, data)
      file_header = [
        data.length # Uncompressed file length - 8 bytes
      ].pack('Q<')
      File.write(path, file_header + LZFSE.lzfse_compress(data))
    end

    def self.strip_nil_values(dict)
      dict.reject { |_, v| v.nil? }
    end
  end
end

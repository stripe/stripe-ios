#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'digest'
require 'fileutils'
require 'set'

# Script to generate short hash-based keys for localized strings
# This replaces long English text keys with deterministic 5-6 character hashes

class LocalizationKeyGenerator
  def initialize
    @mappings = []
    @used_keys = Set.new
    @key_length = 5
  end

  def run
    puts "🔍 Finding all English Localizable.strings files..."
    english_files = find_english_strings_files
    puts "Found #{english_files.size} English localization files\n\n"

    english_files.each do |file|
      process_file(file)
    end

    write_mapping_file
    print_summary
  end

  private

  def find_english_strings_files
    # Find all en.lproj/Localizable.strings files in the main modules
    # Exclude Example directories
    Dir.glob('*/*/Resources/**/en.lproj/Localizable.strings')
       .reject { |f| f.include?('Example/') }
       .sort
  end

  def process_file(file_path)
    module_name = extract_module_name(file_path)
    puts "📦 Processing #{module_name}..."

    content = File.read(file_path)
    entries = parse_strings_file(content)

    puts "   Found #{entries.size} strings"

    entries.each do |entry|
      new_key = generate_unique_key(entry[:key], module_name)

      @mappings << {
        module: module_name,
        oldKey: entry[:key],
        newKey: new_key,
        comment: entry[:comment],
        value: entry[:value],
        file: file_path
      }
    end

    puts "   ✓ Processed #{entries.size} strings\n"
  end

  def extract_module_name(file_path)
    # Extract module name from path like "StripeCore/StripeCore/Resources/..."
    parts = file_path.split('/')
    parts[0] # First directory is the module name
  end

  def parse_strings_file(content)
    entries = []
    current_comment = nil

    # Parse .strings file format:
    # /* Comment */
    # "Key" = "Value";

    lines = content.split("\n")
    i = 0

    while i < lines.size
      line = lines[i].strip

      # Check for comment
      if line.start_with?('/*') && line.end_with?('*/')
        current_comment = line[2..-3].strip
        i += 1
        next
      elsif line.start_with?('/*')
        # Multi-line comment start
        current_comment = line[2..-1].strip
        i += 1
        while i < lines.size && !lines[i].include?('*/')
          current_comment += ' ' + lines[i].strip
          i += 1
        end
        if i < lines.size
          current_comment += ' ' + lines[i].strip.gsub('*/', '').strip
        end
        i += 1
        next
      end

      # Check for key-value pair
      if line =~ /"(.+?)"\s*=\s*"(.*?)";$/
        key = $1
        value = $2

        entries << {
          key: key,
          value: value,
          comment: current_comment
        }

        current_comment = nil
      end

      i += 1
    end

    entries
  end

  def generate_unique_key(original_key, module_name)
    # Generate deterministic hash from original key
    # Use SHA256 and take first N characters
    hash = Digest::SHA256.hexdigest(original_key)

    # Try increasing lengths until we find a unique key
    length = @key_length
    loop do
      candidate = hash[0, length]

      if @used_keys.include?(candidate)
        # Collision! Try longer key
        length += 1
        if length > hash.length
          # This should never happen with SHA256, but just in case
          raise "Unable to generate unique key for: #{original_key}"
        end
        next
      else
        @used_keys.add(candidate)
        return candidate
      end
    end
  end

  def write_mapping_file
    output_file = 'localization_key_mapping.json'
    puts "\n📝 Writing mapping file to #{output_file}..."

    File.write(output_file, JSON.pretty_generate(@mappings))

    puts "✓ Mapping file written successfully"
  end

  def print_summary
    puts "\n" + "="*60
    puts "Summary"
    puts "="*60

    by_module = @mappings.group_by { |m| m[:module] }

    by_module.each do |module_name, mappings|
      puts "#{module_name}: #{mappings.size} strings"
    end

    puts "\nTotal: #{@mappings.size} strings"

    # Calculate key length distribution
    key_lengths = @mappings.map { |m| m[:newKey].length }
    puts "Key lengths: #{key_lengths.min}-#{key_lengths.max} characters"

    # Calculate size savings
    old_total = @mappings.sum { |m| m[:oldKey].length }
    new_total = @mappings.sum { |m| m[:newKey].length }
    savings = old_total - new_total

    puts "\nSize savings per language:"
    puts "  Old total: #{old_total} characters"
    puts "  New total: #{new_total} characters"
    puts "  Savings: #{savings} characters (~#{savings / 1024.0}KB)"
    puts "  Savings across 41 languages: ~#{(savings * 41) / 1024.0}KB"
    puts "="*60
  end
end

# Run the generator
if __FILE__ == $0
  generator = LocalizationKeyGenerator.new
  generator.run
end

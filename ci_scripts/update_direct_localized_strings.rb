#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# Script to update direct STPLocalizedString calls in Swift files
# Finds patterns like: STPLocalizedString("English text", "comment")
# Replaces with: STPLocalizedString("hash", "comment")

class DirectLocalizedStringUpdater
  def initialize(mapping_file = 'localization_key_mapping.json')
    @mapping_file = mapping_file
    @mappings = []
    @key_lookup = {}
    @files_updated = []
  end

  def run(swift_files)
    load_mappings

    swift_files.each do |file|
      update_file(file)
    end

    print_summary
  end

  private

  def load_mappings
    puts "📖 Loading mapping file: #{@mapping_file}..."

    unless File.exist?(@mapping_file)
      raise "Mapping file not found: #{@mapping_file}"
    end

    @mappings = JSON.parse(File.read(@mapping_file), symbolize_names: true)

    # Create a lookup hash for quick access
    @mappings.each do |mapping|
      @key_lookup[mapping[:oldKey]] = mapping[:newKey]
    end

    puts "✓ Loaded #{@mappings.size} mappings\n\n"
  end

  def update_file(file_path)
    content = File.read(file_path)
    original_content = content.dup
    updates = 0

    # Pattern to match: STPLocalizedString("text", "comment")
    # We need to be careful about escaping and multiline strings
    pattern = /STPLocalizedString\(\s*"([^"]+)"\s*,/

    # Sort keys by length (longest first) to avoid partial replacements
    sorted_keys = @key_lookup.keys.sort_by { |k| -k.length }

    sorted_keys.each do |old_key|
      new_key = @key_lookup[old_key]
      escaped_old_key = Regexp.escape(old_key)

      # Match the pattern with this specific key
      key_pattern = /STPLocalizedString\(\s*"#{escaped_old_key}"\s*,/

      if content.match?(key_pattern)
        content.gsub!(key_pattern, "STPLocalizedString(\"#{new_key}\",")
        updates += 1
      end
    end

    if content != original_content
      File.write(file_path, content)
      @files_updated << file_path
      puts "  ✓ Updated #{file_path} (#{updates} replacements)"
    else
      puts "  - No changes needed for #{file_path}"
    end
  end

  def print_summary
    puts "\n" + "="*60
    puts "Summary"
    puts "="*60
    puts "Updated #{@files_updated.size} Swift files with direct STPLocalizedString calls"
    puts "="*60
  end
end

# Run the updater
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: #{$0} <swift_file1> <swift_file2> ..."
    exit 1
  end

  updater = DirectLocalizedStringUpdater.new
  updater.run(ARGV)
end

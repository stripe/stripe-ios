#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'

# Script to apply the new hash-based keys to all localization files
# Reads the mapping from localization_key_mapping.json and updates:
# 1. All Localizable.strings files (English and translations)
# 2. All String+Localized.swift files

class LocalizationKeyApplier
  def initialize(mapping_file = 'localization_key_mapping.json')
    @mapping_file = mapping_file
    @mappings = []
    @mappings_by_module = {}
  end

  def run
    load_mappings
    update_localizable_strings_files
    update_string_localized_files
    print_summary
  end

  private

  def load_mappings
    puts "📖 Loading mapping file: #{@mapping_file}..."

    unless File.exist?(@mapping_file)
      raise "Mapping file not found: #{@mapping_file}. Run generate_localization_keys.rb first."
    end

    @mappings = JSON.parse(File.read(@mapping_file), symbolize_names: true)
    @mappings_by_module = @mappings.group_by { |m| m[:module] }

    puts "✓ Loaded #{@mappings.size} mappings for #{@mappings_by_module.keys.size} modules\n\n"
  end

  def update_localizable_strings_files
    puts "🔄 Updating Localizable.strings files..."

    @mappings_by_module.each do |module_name, module_mappings|
      update_module_strings_files(module_name, module_mappings)
    end

    puts "✓ All Localizable.strings files updated\n\n"
  end

  def update_module_strings_files(module_name, module_mappings)
    # Find all Localizable.strings files for this module
    # Pattern: ModuleName/ModuleName/Resources/**/Localizable.strings
    pattern = "#{module_name}/#{module_name}/Resources/**/Localizable.strings"
    files = Dir.glob(pattern).reject { |f| f.include?('Example/') }

    if files.empty?
      puts "  ⚠️  No Localizable.strings files found for #{module_name}"
      return
    end

    puts "  📦 #{module_name}: Updating #{files.size} language files..."

    files.each do |file|
      language = extract_language(file)
      update_strings_file(file, module_mappings, language)
    end
  end

  def extract_language(file_path)
    # Extract language from path like ".../en.lproj/Localizable.strings"
    if file_path =~ /\/([^\/]+)\.lproj\/Localizable\.strings$/
      $1
    else
      'unknown'
    end
  end

  def update_strings_file(file_path, module_mappings, language)
    content = File.read(file_path)
    original_content = content.dup
    updated_count = 0

    # Sort mappings by key length (longest first) to avoid partial replacements
    sorted_mappings = module_mappings.sort_by { |m| -m[:oldKey].length }

    sorted_mappings.each do |mapping|
      old_key = mapping[:oldKey]
      new_key = mapping[:newKey]

      # Escape special regex characters in the old key
      escaped_old_key = Regexp.escape(old_key)

      # Replace "oldKey" with "newKey" (preserving quotes and format)
      # This handles both key and value positions in the strings file
      pattern = /"#{escaped_old_key}"/

      if content.match?(pattern)
        # Only replace the key part (first occurrence on each line)
        # Use gsub with a block to only replace the first occurrence on lines starting with "
        lines = content.split("\n")
        lines.map! do |line|
          if line.strip.start_with?('"') && line.include?("\"#{old_key}\"")
            # This is a key-value line, replace only the first occurrence (the key)
            line.sub(/"#{escaped_old_key}"(\s*=)/, "\"#{new_key}\"\\1")
          else
            line
          end
        end
        content = lines.join("\n")
        updated_count += 1
      end
    end

    if content != original_content
      File.write(file_path, content)
      # puts "     ✓ #{language}: Updated #{updated_count} keys"
    else
      # puts "     - #{language}: No changes needed"
    end
  end

  def update_string_localized_files
    puts "🔄 Updating String+Localized.swift files..."

    @mappings_by_module.each do |module_name, module_mappings|
      update_string_localized_file(module_name, module_mappings)
    end

    puts "✓ All String+Localized.swift files updated\n\n"
  end

  def update_string_localized_file(module_name, module_mappings)
    # Find the String+Localized.swift file for this module
    # Common locations:
    patterns = [
      "#{module_name}/#{module_name}/Source/Helpers/String+Localized.swift",
      "#{module_name}/#{module_name}/Source/**/String+Localized.swift",
      "#{module_name}/#{module_name}/**/String+Localized.swift"
    ]

    file_path = nil
    patterns.each do |pattern|
      matches = Dir.glob(pattern)
      if matches.any?
        file_path = matches.first
        break
      end
    end

    unless file_path
      puts "  ⚠️  No String+Localized.swift found for #{module_name}"
      return
    end

    puts "  📦 #{module_name}: Updating #{file_path}..."

    content = File.read(file_path)
    original_content = content.dup
    updated_count = 0

    # Sort mappings by key length (longest first) to avoid partial replacements
    sorted_mappings = module_mappings.sort_by { |m| -m[:oldKey].length }

    sorted_mappings.each do |mapping|
      old_key = mapping[:oldKey]
      new_key = mapping[:newKey]
      comment = mapping[:comment]

      # Escape special regex characters
      escaped_old_key = Regexp.escape(old_key)

      # Pattern to match: STPLocalizedString("oldKey", ...)
      # We want to replace it with: STPLocalizedString("newKey", ...)
      # and optionally add a comment showing the original English text

      pattern = /STPLocalizedString\("#{escaped_old_key}",/

      if content.match?(pattern)
        # Replace the key
        content.gsub!(pattern, "STPLocalizedString(\"#{new_key}\",")
        updated_count += 1
      end
    end

    if content != original_content
      File.write(file_path, content)
      puts "     ✓ Updated #{updated_count} string references"
    else
      puts "     - No changes needed"
    end
  end

  def print_summary
    puts "\n" + "="*60
    puts "Summary"
    puts "="*60

    total_strings_files = 0
    total_swift_files = 0

    @mappings_by_module.each do |module_name, _|
      strings_count = Dir.glob("#{module_name}/#{module_name}/Resources/**/Localizable.strings").reject { |f| f.include?('Example/') }.size
      swift_count = Dir.glob("#{module_name}/#{module_name}/**/String+Localized.swift").size

      total_strings_files += strings_count
      total_swift_files += swift_count
    end

    puts "Updated:"
    puts "  - #{total_strings_files} Localizable.strings files"
    puts "  - #{total_swift_files} String+Localized.swift files"
    puts "  - #{@mappings.size} unique localized strings"
    puts "\n✅ All files updated successfully!"
    puts "="*60
  end
end

# Run the applier
if __FILE__ == $0
  applier = LocalizationKeyApplier.new
  applier.run
end

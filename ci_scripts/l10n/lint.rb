#!/usr/bin/env ruby

# frozen_string_literal: true

require 'set'
require 'colorize'
require 'dotstrings'

require_relative 'config'

unused_keys = Set.new

def load_strings(path)
  DotStrings.parse_file(path)
rescue Errno::ENOENT
  abort("ERR: Missing strings file: #{path}".red)
rescue DotStrings::ParsingError => e
  abort("ERR (#{path}): #{e.message}".red)
end

LOCALIZATION_DIRECTORIES.each do |localization_dir|
  source_file = load_strings(
    "#{localization_dir}/Resources/Localizations/#{DEVELOPMENT_LANGUAGE}.lproj/Localizable.strings"
  )

  source_keys = source_file.keys

  LANGUAGES.each do |language|
    path = "#{localization_dir}/Resources/Localizations/#{language}.lproj/Localizable.strings"

    puts "Linting #{path}..."
    strings = load_strings(path)

    # Find and remove unused keys.
    (strings.keys - source_keys).each do |key|
      unused_keys << key
      strings.delete(key)
    end

    # Rewrite the file for consistent formatting.
    File.write(path, strings.to_s(comments: false))
  end
end

unless unused_keys.empty?
  puts "WARN: Found and removed #{unused_keys.count} unused keys. Consider removing them from Lokalise:".yellow
  puts ''

  unused_keys.each do |string|
    puts "\"#{string}\"".yellow
  end
end

#!/usr/bin/env ruby

# frozen_string_literal: true

require 'set'
require 'colorize'
require 'dotstrings'

require_relative 'config'

missing_keys = {}

LOCALIZATION_DIRECTORIES.each do |directory|
  development_strings = DotStrings.parse_file(
    "#{directory}/Resources/Localizations/#{DEVELOPMENT_LANGUAGE}.lproj/Localizable.strings"
  )

  LANGUAGES.each do |locale|
    path = "#{directory}/Resources/Localizations/#{locale}.lproj/Localizable.strings"
    puts "Checking #{path}..."

    begin
      strings = DotStrings.parse_file(path)

      diff = development_strings.keys - strings.keys
      diff.each do |key|
        missing_keys[key] = Set.new if missing_keys[key].nil?
        missing_keys[key] << locale
      end
    rescue DotStrings::ParsingError => e
      puts "ERR (#{path}): #{e.message}".red
      exit(1)
    end
  end
end

report = {}

missing_keys.each do |key, locales|
  report[locales] = [] if report[locales].nil?
  report[locales] << key
end

unless report.empty?
  puts 'ERR: Missing localizations detected:'.red
  puts ''

  report.each do |locales, keys|
    puts "#{locales.to_a.join(', ')}:".red
    puts ''

    keys.each do |key|
      puts "\"#{key}\"".red
    end

    puts ""
  end

  exit(1)
end

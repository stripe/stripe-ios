#!/usr/bin/env ruby

# frozen_string_literal: true

require 'colorize'
require 'dotstrings'

require_relative 'config'

def error(string)
  puts "[#{File.basename(__FILE__)}] #{string.red}"
end

def success(string)
  puts "[#{File.basename(__FILE__)}] #{string.green}"
end

should_fail = false
string_to_directory_hash = {}

LOCALIZATION_DIRECTORIES.each do |directory|
  filename = "#{directory}/Resources/Localizations/en.lproj/Localizable.strings"

  file = DotStrings.parse_file(filename)
  strings = file.keys

  strings.each do |string|
    if string_to_directory_hash.key?(string)
      should_fail = true
      error "Duplicated in '#{string_to_directory_hash[string]}' and '#{directory}': '#{string}'"
    else
      string_to_directory_hash[string] = directory
    end
  end
end

if should_fail
  error "Detected duplicate strings between modules. To fix this, reference a constant that calls 'STPLocalizedString' rather than multiple calls to 'STPLocalizedString'."
  abort
else
  success 'All good!'
end

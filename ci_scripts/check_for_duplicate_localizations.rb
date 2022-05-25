#!/usr/bin/env ruby

require 'colorize'

def error(string)
  puts "[#{File.basename(__FILE__)}] #{"#{string}".red}"
end

def success(string)
  puts "[#{File.basename(__FILE__)}] #{string.green}"
end

SCRIPT_DIR = __dir__
ROOT_DIR = File.expand_path("..", SCRIPT_DIR)

# Load LOCALIZATION_DIRECTORIES variable
LOCALIZATION_DIRECTORIES=`sh -c 'source #{File.realpath("#{SCRIPT_DIR}/localization_vars.sh")} && echo ${LOCALIZATION_DIRECTORIES[*]}'`.split

should_fail = false
string_to_directory_hash = Hash.new()

LOCALIZATION_DIRECTORIES.each do |directory|
  filename = "#{directory}/Resources/Localizations/en.lproj/Localizable.strings"

  file = File.open(filename)
  file_contents = file.read
  strings = file_contents.scan(/"(.+)" = ".+";/).flatten

  strings.each do |string|
    if string_to_directory_hash.has_key?(string)
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
  success "All good!"
end

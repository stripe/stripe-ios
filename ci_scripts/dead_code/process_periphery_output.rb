#!/usr/bin/env ruby
require 'json'

# Check for correct usage
if ARGV.length != 2
  puts "Usage: ruby ci_scripts/dead_code/process_periphery_output.rb <periphery_output_file> <output_json_file>"
  exit 1
end

periphery_output_file = ARGV[0]
output_json_file = ARGV[1]

# Initialize an empty hash to store the unused code entries
unused_code = {}

File.foreach(periphery_output_file) do |line|
  line.chomp!

  # Remove full file path and extract relevant information
  # Example line:
  # /path/to/file/SimpleMandateTextView.swift:29:17: warning: Initializer 'init(mandateText:theme:)' is unused

  # Use a regular expression to parse the line
  if line =~ %r{^(?:.*/)?(.+?)(?::\d+:\d+)?\s*:?\s*warning:\s*(?:.+?)\s+'(.+?)'\s+is unused$}
    filename = $1
    identifier = $2

    # Create a unique key by combining the filename and identifier
    key = "#{filename}_#{identifier}"

    # Store the original line as the value
    unused_code[key] = "#{filename}: warning: #{identifier} is unused"
  else
    # Handle lines that don't match the expected pattern
    # You can log or skip them
    puts "Skipping unrecognized line: #{line}"
  end
end

# Write the hash to a JSON file
File.open(output_json_file, 'w') do |f|
  f.write(JSON.pretty_generate(unused_code))
end

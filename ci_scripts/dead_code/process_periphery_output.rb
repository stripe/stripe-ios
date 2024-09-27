#!/usr/bin/env ruby
require 'json'

# Check for correct usage
if ARGV.length != 2
  puts "Usage: ruby ci_scripts/dead_code/process_periphery_output.rb <periphery_output_file> <output_json_file>"
  exit 1
end

periphery_output_file = ARGV[0]
output_json_file = ARGV[1]

unused_code = {}

File.foreach(periphery_output_file) do |line|
  line.chomp!

  # Remove full file path and extract relevant information
  # Example line:
  # /path/to/file/SimpleMandateTextView.swift:29:17: warning: Initializer 'init(mandateText:theme:)' is unused

  if line =~ %r{^(?:.*/)?(.+?)(?::\d+:\d+)?\s*:?\s*warning:\s*(?:.+?)\s+'(.+?)'\s+is unused$}
    filename = $1
    identifier = $2

    key = "#{filename}_#{identifier}"

    unused_code[key] = "#{filename}: warning: #{identifier} is unused"
  else
    # Handle lines that don't match the expected pattern
    puts "Skipping unrecognized line: #{line}"
  end
end

File.open(output_json_file, 'w') do |f|
  f.write(JSON.pretty_generate(unused_code))
end

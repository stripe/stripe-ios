#!/usr/bin/env ruby
require 'json'

# Check for correct usage
if ARGV.length != 2
  puts "Usage: ruby ci_scripts/dead_code/compare_unused_code.rb <master_json_file> <feature_json_file>"
  exit 1
end

master_json_file = ARGV[0]
feature_json_file = ARGV[1]
diff_json_file = "new_dead_code.json"

# Load JSON data
begin
  master_unused_code = JSON.parse(File.read(master_json_file))
rescue Errno::ENOENT
  puts "Master JSON file not found: #{master_json_file}"
  master_unused_code = {}
rescue JSON::ParserError => e
  puts "Error parsing master JSON file: #{e}"
  master_unused_code = {}
end

begin
  feature_unused_code = JSON.parse(File.read(feature_json_file))
rescue Errno::ENOENT
  puts "Feature JSON file not found: #{feature_json_file}"
  feature_unused_code = {}
rescue JSON::ParserError => e
  puts "Error parsing feature JSON file: #{e}"
  feature_unused_code = {}
end

# Compute the difference: keys present in feature_data but not in master_data
new_dead_code = feature_unused_code.reject { |k, _| master_unused_code.key?(k) }

if new_dead_code.size > 200
  puts "More than 200 keys present, skipping. This usually happens if a build fails"
elsif new_dead_code.empty?
  puts "No new dead code detected."
else
  File.write(diff_json_file, JSON.pretty_generate(new_dead_code) + "\n")
end

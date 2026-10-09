#!/usr/bin/env ruby
require 'json'

# Check for correct usage
if ARGV.length != 2
  puts "Usage: ruby ci_scripts/dead_code/compare_unused_code.rb <master_json_file> <feature_json_file>"
  exit 1
end

master_json_file = ARGV[0]
feature_json_file = ARGV[1]
diff_text_file = "new_dead_code.txt"

File.delete(diff_text_file) if File.exist?(diff_text_file)

def read_report(path)
  report = JSON.parse(File.read(path))
  unless report.is_a?(Hash) && report.all? { |key, value| key.is_a?(String) && value.is_a?(String) }
    abort "Invalid dead-code report: #{path}"
  end
  report
end

master_unused_code = read_report(master_json_file)
feature_unused_code = read_report(feature_json_file)

# Compute the difference: keys present in feature_data but not in master_data
new_dead_code = feature_unused_code.reject { |k, _| master_unused_code.key?(k) }

if new_dead_code.size > 300
  abort "More than 300 new findings; inspect the scan results before accepting this comparison."
elsif new_dead_code.empty?
  puts "No new dead code detected."
else
  # Extract values and write to the file as plain text
  File.open(diff_text_file, 'w') do |file|
    new_dead_code.each_value do |value|
      file.puts(value)
    end
  end
end

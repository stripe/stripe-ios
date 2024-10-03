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

  # Process lines that contain ".swift" and either "unused" or "warning" (case-insensitive)
  if line.include?('.swift') && line.downcase.include?('warning')
    # Split the line into up to 4 parts based on colon
    # Example line:
    # /path/to/file/SimpleMandateTextView.swift:29:17: warning: Initializer 'init(mandateText:theme:)' is unused

    parts = line.split(':', 4) # Split into 4 parts at most

    if parts.length >= 4
      file_path = parts[0].strip
      line_num = parts[1].strip # Not needed
      # col_num = parts[2].strip  # Not needed
      warning_message = parts[3].strip

      # Extract the filename from the file path
      filename = File.basename(file_path)

      # Remove 'warning:' from the warning_message if present (case-insensitive)
      warning_text = warning_message.sub(/^warning:\s*/i, '')

      # Construct the full warning message without line and column numbers
      # Format: Filename.swift: warning: Message
      full_warning_key = "#{filename}: warning: #{warning_text}"
      full_warning_value = "#{filename}:#{line_num} warning: #{warning_text}"

      # Assign the same string as both key and value
      unused_code[full_warning_key] = full_warning_value

    else
      puts "Skipping improperly formatted line: #{line}"
    end
  else
    # Handle lines that don't match criteria
  end
end


# Write the unused_code hash to the output JSON file with a newline at the end
File.open(output_json_file, 'w') do |f|
  puts unused_code
  f.write(JSON.pretty_generate(unused_code) + "\n")
end

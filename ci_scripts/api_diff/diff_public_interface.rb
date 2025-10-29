require 'open3'
require 'tempfile'
require_relative 'get_frameworks'
require_relative 'sort_swift_interface'

def sort_interface(input_path)
  # Create a temporary file for sorted output
  temp_file = Tempfile.new(['sorted_interface', '.swiftinterface'])

  # Read and sort the interface
  content = File.read(input_path)
  sorter = SwiftInterfaceSorter.new(content)
  sorted_content = sorter.sort

  # Write sorted content to temp file
  File.write(temp_file.path, sorted_content)

  temp_file
end

def diff(old_path, new_path)
  # Sort both interface files before diffing
  sorted_old = sort_interface(old_path)
  sorted_new = sort_interface(new_path)

  stdout, _stderr, _status = Open3.capture3("diff", "-u", sorted_old.path, sorted_new.path)

  diff_string = stdout.lines.map do |line|
    case line[0..1]
    when "+ " then "+ #{line[2..-1].strip}"
    when "- " then "- #{line[2..-1].strip}"
    else nil
    end
  end.compact.join("\n")

  # Clean up temp files
  sorted_old.close
  sorted_old.unlink
  sorted_new.close
  sorted_new.unlink

  return diff_string
end

final_diff_string = ""

for framework_name in GetFrameworks.framework_names("./modules.yaml")
  master_interface_path = "#{framework_name}-master.xcframework/ios-arm64_x86_64-simulator/#{framework_name}.framework/Modules/#{framework_name}.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
  branch_interface_path = "#{framework_name}-new.xcframework/ios-arm64_x86_64-simulator/#{framework_name}.framework/Modules/#{framework_name}.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
  module_diff = diff(master_interface_path, branch_interface_path)

  processed_lines = module_diff.lines.map do |line|
    if line.include?('public')
      # Remove everything before 'public', including any leading characters
      line.sub(/^(.*?)(public)/, '\1\2')  # Keep the original prefix
    else
      # Keep the line as is
      line
    end
  end
  
  # Join the processed lines back into a string
  processed_string = processed_lines.join

	# Add the framework headers and the diff to the final diff string
	unless module_diff.empty?
		final_diff_string += "\n### #{framework_name}\n```diff\n#{processed_string}\n```\n"
	end
end

# Write the final diff string to a file
if not final_diff_string.empty?
	File.open("diff_result.txt", 'w') { |f| f.write final_diff_string }
end
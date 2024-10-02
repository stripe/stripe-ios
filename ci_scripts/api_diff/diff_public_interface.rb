require 'open3'
require_relative 'get_frameworks'

def diff(old_path, new_path)
  stdout, _stderr, _status = Open3.capture3("diff", "-u", old_path, new_path)

  diff_string = stdout.lines.map do |line|
    case line[0..1]
    when "+ " then "+ #{line[2..-1].strip}"
    when "- " then "- #{line[2..-1].strip}"
    else nil
    end
  end.compact.join("\n")

  return diff_string
end

final_diff_string = ""

for framework_name in GetFrameworks.framework_names("./modules.yaml")
  master_interface_path = "#{framework_name}-master.xcframework/ios-arm64_x86_64-simulator/#{framework_name}.framework/Modules/#{framework_name}.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
  branch_interface_path = "#{framework_name}-new.xcframework/ios-arm64_x86_64-simulator/#{framework_name}.framework/Modules/#{framework_name}.swiftmodule/arm64-apple-ios-simulator.swiftinterface"
  module_diff = diff(master_interface_path, branch_interface_path)

	# Add the framework headers and the diff to the final diff string
	unless module_diff.empty?
		final_diff_string += "\n### #{framework_name}\n```diff\n#{module_diff}\n```\n"
	end
end

# Process the final diff string
unless final_diff_string.empty?
  # Split the string into lines and process each line
  processed_lines = final_diff_string.lines.map do |line|
    # Preserve the diff indicator at the beginning
    if line =~ /^(\+|-)\s*(.*)$/
      diff_symbol = $1
      rest_of_line = $2
      # Remove all occurrences of "@objc"
      rest_of_line.gsub!(/@objc\s*/, '')
      "#{diff_symbol} #{rest_of_line}"
    else
      # If the line doesn't start with + or -, just remove "@objc"
      line.gsub(/@objc\s*/, '')
    end
  end

  # Join the processed lines back into a single string
  formatted_diff_string = processed_lines.join

  # Write the formatted diff string to a file
  diff_result_path = File.join(base_dir, 'diff_result.txt')
  File.open(diff_result_path, 'w') { |f| f.write(formatted_diff_string) }
end
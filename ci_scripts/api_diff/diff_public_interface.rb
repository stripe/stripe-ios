require 'open3'
require 'tempfile'
require_relative 'get_frameworks'

def diff(old_path, new_path)
  # Read and sort both files alphabetically
  old_lines = File.readlines(old_path).sort
  new_lines = File.readlines(new_path).sort

  # Create temporary files with sorted content
  old_temp = Tempfile.new(['sorted_old', '.swiftinterface'])
  new_temp = Tempfile.new(['sorted_new', '.swiftinterface'])

  begin
    old_temp.write(old_lines.join)
    old_temp.flush
    new_temp.write(new_lines.join)
    new_temp.flush

    stdout, _stderr, _status = Open3.capture3("diff", "-u", old_temp.path, new_temp.path)

    diff_string = stdout.lines.map do |line|
      case line[0..1]
      when "+ " then "+ #{line[2..-1].strip}"
      when "- " then "- #{line[2..-1].strip}"
      else nil
      end
    end.compact.join("\n")

    return diff_string
  ensure
    old_temp.close
    old_temp.unlink
    new_temp.close
    new_temp.unlink
  end
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
require 'open3'
require 'tempfile'
require_relative 'get_frameworks'

PUBLIC_SEVERITY = 'public'.freeze
SPI_SEVERITY = 'spi'.freeze
NO_SEVERITY = 'none'.freeze
DIFF_OUTPUT_PATH = 'diff_result.txt'.freeze
SEVERITY_OUTPUT_PATH = 'api_change_severity.txt'.freeze

def sorted_diff_lines(old_path, new_path)
  old_lines = File.readlines(old_path).sort
  new_lines = File.readlines(new_path).sort

  old_temp = Tempfile.new(['sorted_old', File.extname(old_path)])
  new_temp = Tempfile.new(['sorted_new', File.extname(new_path)])

  begin
    old_temp.write(old_lines.join)
    old_temp.flush
    new_temp.write(new_lines.join)
    new_temp.flush

    stdout, _stderr, _status = Open3.capture3('diff', '-u', old_temp.path, new_temp.path)
    stdout.lines.filter_map do |line|
      next if line.start_with?('+++', '---', '@@')
      next unless line.start_with?('+', '-')

      content = line[1..].rstrip
      next if content.empty?

      "#{line[0]}#{content}"
    end
  ensure
    old_temp.close
    old_temp.unlink
    new_temp.close
    new_temp.unlink
  end
end

def non_stp_spi_line?(line)
  spi_names = line.scan(/@_spi\(([^)]+)\)/).flatten.map(&:strip)
  spi_names.any? { |spi_name| spi_name != 'STP' }
end

def has_non_additive_changes?(lines)
  lines.any? { |line| line.start_with?('-') }
end

def render_module_diff(framework_name, public_lines, spi_lines)
  return '' if public_lines.empty? && spi_lines.empty?

  sections = ["\n### #{framework_name}\n"]
  unless public_lines.empty?
    sections << "#### Public API\n```diff\n#{public_lines.join("\n")}\n```\n"
  end
  unless spi_lines.empty?
    sections << "#### SPI API\n```diff\n#{spi_lines.join("\n")}\n```\n"
  end
  sections.join
end

def write_output(path, content)
  File.delete(path) if File.exist?(path)
  File.write(path, content)
end

final_diff_string = +''
severity = NO_SEVERITY

GetFrameworks.framework_names('./modules.yaml').each do |framework_name|
  public_interface_dir = "#{framework_name}.framework/Modules/#{framework_name}.swiftmodule"
  simulator_slice = 'ios-arm64_x86_64-simulator'

  master_public_interface_path = "#{framework_name}-master.xcframework/#{simulator_slice}/#{public_interface_dir}/arm64-apple-ios-simulator.swiftinterface"
  branch_public_interface_path = "#{framework_name}-new.xcframework/#{simulator_slice}/#{public_interface_dir}/arm64-apple-ios-simulator.swiftinterface"
  public_diff_lines = sorted_diff_lines(master_public_interface_path, branch_public_interface_path)

  master_private_interface_path = "#{framework_name}-master.xcframework/#{simulator_slice}/#{public_interface_dir}/arm64-apple-ios-simulator.private.swiftinterface"
  branch_private_interface_path = "#{framework_name}-new.xcframework/#{simulator_slice}/#{public_interface_dir}/arm64-apple-ios-simulator.private.swiftinterface"
  spi_diff_lines = sorted_diff_lines(master_private_interface_path, branch_private_interface_path).select do |line|
    line.include?('@_spi(') && non_stp_spi_line?(line)
  end

  if has_non_additive_changes?(public_diff_lines)
    severity = PUBLIC_SEVERITY
  elsif has_non_additive_changes?(spi_diff_lines) && severity == NO_SEVERITY
    severity = SPI_SEVERITY
  end

  final_diff_string << render_module_diff(framework_name, public_diff_lines, spi_diff_lines)
end

write_output(SEVERITY_OUTPUT_PATH, severity)
if final_diff_string.empty?
  File.delete(DIFF_OUTPUT_PATH) if File.exist?(DIFF_OUTPUT_PATH)
else
  write_output(DIFF_OUTPUT_PATH, final_diff_string)
end

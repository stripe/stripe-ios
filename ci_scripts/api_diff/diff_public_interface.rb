require 'open3'
require 'fileutils'
require_relative 'get_frameworks'

def build_swift_package(swift_package_dir, swift_script_path)
  # Create the Swift package directory
  FileUtils.mkdir_p(swift_package_dir)

  # Initialize the Swift package
  Dir.chdir(swift_package_dir) do
    system('swift package init --type executable')

    # Modify Package.swift to add dependencies
    package_swift_path = 'Package.swift'
    package_swift_content = <<~SWIFT
      // swift-tools-version:5.9
      import PackageDescription

      let package = Package(
          name: "ProcessDiff",
          platforms: [
              .macOS(.v14),
          ],
          dependencies: [
              .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.0.0")
          ],
          targets: [
              .executableTarget(
                  name: "ProcessDiff",
                  dependencies: [
                      .product(name: "SwiftSyntax", package: "swift-syntax"),
                      .product(name: "SwiftSyntaxParser", package: "swift-syntax")
                  ]
              ),
          ]
      )
    SWIFT

    File.write(package_swift_path, package_swift_content)

    # Copy the Swift script into the correct directory
    sources_dir = File.join('Sources', 'ProcessDiff')
    FileUtils.mkdir_p(sources_dir)

    # Remove any existing main.swift files to avoid conflicts
    existing_main_swift = File.join(sources_dir, 'main.swift')
    FileUtils.rm_f(existing_main_swift)

    # Copy your process_diff.swift to main.swift in the sources directory
    FileUtils.cp(swift_script_path, existing_main_swift)

    # Build the Swift package
    build_status = system('swift build -c release')
    unless build_status
      puts "Error building the Swift package."
      exit 1
    end
  end
end

def swift_diff(old_path, new_path, swift_diff_tool)
  # Run the SwiftDiffTool and capture the output
  stdout, stderr, status = Open3.capture3(swift_diff_tool, old_path, new_path)

  unless status.success?
    puts "Error running process_diff.swift:"
    puts stderr
    exit 1
  end

  diff_output = stdout.strip
  return diff_output
end

# Base directory where the scripts are located
base_dir = File.expand_path(__dir__)

# Path to the process_diff.swift script
swift_script_path = File.join(base_dir, 'process_diff.swift')

# Directory for the Swift package
swift_package_dir = File.join(base_dir, 'ProcessDiff')

# Build the Swift package (only once)
unless File.exist?(File.join(swift_package_dir, '.build', 'release', 'ProcessDiff'))
  build_swift_package(swift_package_dir, swift_script_path)
end

# Path to the SwiftDiffTool executable
swift_diff_tool = File.join(swift_package_dir, '.build', 'release', 'ProcessDiff')

final_diff_string = ""

# Iterate over the modules
GetFrameworks.framework_names(File.join(base_dir, 'modules.yaml')).each do |framework_name|
  master_interface_path = File.join(
    base_dir,
    "#{framework_name}-master.xcframework",
    "ios-arm64_x86_64-simulator",
    "#{framework_name}.framework",
    "Modules",
    "#{framework_name}.swiftmodule",
    "arm64-apple-ios-simulator.swiftinterface"
  )

  branch_interface_path = File.join(
    base_dir,
    "#{framework_name}-new.xcframework",
    "ios-arm64_x86_64-simulator",
    "#{framework_name}.framework",
    "Modules",
    "#{framework_name}.swiftmodule",
    "arm64-apple-ios-simulator.swiftinterface"
  )

  # Check if interface files exist
  unless File.exist?(master_interface_path) && File.exist?(branch_interface_path)
    puts "Interface files not found for #{framework_name}. Skipping..."
    next
  end

  module_diff = swift_diff(master_interface_path, branch_interface_path, swift_diff_tool)

  # Add the framework headers and the diff to the final diff string
  unless module_diff.empty?
    final_diff_string += "\n### #{framework_name}\n```diff\n#{module_diff}\n```\n"
  end
end

# Write the final diff string to a file
unless final_diff_string.empty?
  diff_result_path = File.join(base_dir, 'diff_result.txt')
  File.open(diff_result_path, 'w') { |f| f.write(final_diff_string) }
end

#!/usr/bin/env ruby

require 'pathname'
require 'set'

# This script checks for any symbols in our bridging headers
# that do not have a namespace prefix

SCRIPT_DIR = __dir__
if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?
    abort "Unable to find SCRIPT_DIR"
end

ROOT_DIR = File.expand_path("..", SCRIPT_DIR)
if ROOT_DIR.nil? || ROOT_DIR.empty?
    abort "Unable to find ROOT_DIR"
end
ROOT_DIR_PATHNAME = Pathname(ROOT_DIR)

MISSING_PREFIX_REGEX = %r{
    @(interface|protocol)\s+ # Find @interface or @protocol
    \b(?!STP|Stripe|_stpinternal|UI|PK|NS)(\w+)\b # Followed by a word that does not begin with STP, Stripe, _stpinternal, UI, PK, or NS
    (?!.*\(SWIFT_EXTENSION) # And that isn't an extension
    }x

Dir.chdir(ROOT_DIR)

xcodebuild_command = <<~HEREDOC
  xcodebuild clean build \
  -quiet \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath build-ci-symbol-check
HEREDOC
puts xcodebuild_command
system xcodebuild_command
exit $?.exitstatus unless $?.success?

# colorization helpers from https://stackoverflow.com/a/11482430
class String
     # colorization
     def colorize(color_code)
        "\e[#{color_code}m#{self}\e[0m"
     end
 
     def red
        colorize(31)
     end
 
     def green
        colorize(32)
     end
 
     def yellow
        colorize(33)
     end
 
     def light_blue
        colorize(36)
     end
 end

SWIFT_FILES = Dir.glob("#{ROOT_DIR}/**/*.swift")
def find_declaration(symbol, is_class)
     found = false
     prefix = is_class ? "class" : "protocol"
     SWIFT_FILES.each do |file_name|
        File.open(file_name, 'r') do |file|
            file.readlines.each_with_index do |line, n|
                case (line)
                when /#{prefix}\s+\b#{symbol}\b/
                    puts symbol.red
                    puts "Declared in " + Pathname(file_name).relative_path_from(ROOT_DIR_PATHNAME).to_s.light_blue + " Line #{n+1}\n".light_blue
                    found = true
                    break
                end
            end
        end
        break if found
     end
 end

puts "Checking for missing namespaces in Objective-C header..."
found_missing_namespace = false
found_symbols = Set[]
Dir.glob("build-ci-symbol-check/**/*-Swift.h").each do |file_name|
     File.open(file_name, 'r') do |file|
        file.read().scan(MISSING_PREFIX_REGEX).each do |symbol_name|
            if !found_missing_namespace
                puts "Found symbols without an expected prefix!".red
                puts "\nFor each of the symbols listed below you can:"
                puts "\t1. Stop subclassing NSObject if it’s not necessary".yellow
                puts "\t2. Give the class an objc name like @objc(STP_Internal_xxx) and add docstrings marking that it should not be used externally".yellow
                puts "\t3. If this symbol comes from a system Framework update the MISSING_PREFIX_REGEX in this script to allow that frameworks prefix.\n".yellow
                found_missing_namespace = true
            end
            if !found_symbols.include?(symbol_name[1]) # Some symbols are included in multiple bridging headers for different modules
                found_symbols.add(symbol_name[1])
                find_declaration(symbol_name[1], symbol_name[0] == "interface")
            end
        end
     end
end

exit found_missing_namespace ? 1 : 0

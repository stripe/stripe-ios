#!/usr/bin/env ruby
# encoding: utf-8

require 'optparse'

require_relative 'rules/property_rule'
require_relative 'utils/logger'

usage = 'Usage: linter_tests.rb [--force] [directory]'

# Parse options from command line
options = {}

OptionParser.new do |opts|
  opts.banner = usage

  opts.on('-f', '--force', 'Force linter to write changes. Will perform dry run by default.') do |force|
    options[:force] = force
  end

  opts.on('-v', '--verbose', 'Enable logging debug messages.') do |verbose|
    options[:verbose] = verbose
  end
end.parse!

# Parse directory argument
if ARGV.length != 1
  print "#{usage}\n"
  exit 1
end

# Configure logger
Utils::Logger.verbose_mode = options[:verbose]

# Load file paths
file_paths = []

Dir.glob(ARGV[0] + '/**/*.h') do |file_path|
  file_paths.push(file_path)
end

Dir.glob(ARGV[0] + '/**/*.m') do |file_path|
  file_paths << file_path
end

# Apply rules
file_paths.each do |file_path|
  file_name = file_path.split('/').last
  file_lines = File.readlines(file_path).map(&:chomp)

  # Property rule
  file_lines = Rules::PropertyRule.apply_rule(file_name, file_lines)

  # Apply changes if needed
  if options[:force]
    File.open(file_path, 'w') do |file|
      file.write(file_lines.join("\n") + "\n")
    end
  end
end

# Print summary
if !options[:force]
  print "Run linter_tests.rb with `--force` option to autocorrect\n"
end

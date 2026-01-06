#!/usr/bin/env ruby

# frozen_string_literal: true

# This script determines which module tests to run based on changed files in a PR.
# It parses podspecs to build a dependency graph, identifies which modules are affected
# by the changes, and sets environment variables for Bitrise to conditionally run tests.
#
# Usage:
#   ruby ci_scripts/determine_tests_to_run.rb
#
# Output:
#   Sets environment variables like RUN_STRIPEPAYMENTSHEET=true via envman

require 'yaml'
require 'set'

# ============================================================================
# Configuration Constants
# ============================================================================

# Files/directories that when changed should trigger ALL tests (as regexes)
GLOBAL_TRIGGER_PATTERNS = [
  # /^ci_scripts\//,
  /^Package\.swift$/,
  /^Gemfile$/,
  /^Gemfile\.lock$/,
  # /^bitrise\.yml$/,
  /^\.swiftlint\.yml$/,
  /^BuildConfigurations\//,
  /^fastlane\//,
  /^Stripe\.xcworkspace\//,
  /^modules\.yaml$/,
  /^\.github\//,
  /^Brewfile$/,
  /^VERSION$/,
  /\.podspec$/
].freeze

# Mapping from directory name to module name (for special cases)
DIRECTORY_TO_MODULE = {
  'Stripe3DS2' => 'StripePayments' # 3DS2 is part of StripePayments
}.freeze

# Environment variable name prefix for Bitrise
ENV_VAR_PREFIX = 'RUN_'

# ============================================================================
# Podspec Dependency Parser
# ============================================================================

class DependencyParser
  def initialize(repo_root)
    @repo_root = repo_root
    @modules_yaml = YAML.load_file(File.join(repo_root, 'modules.yaml'))
  end

  # Parse all podspecs and return direct dependencies for each module
  # Returns: { 'StripePaymentSheet' => ['StripeCore', 'StripePayments', ...], ... }
  def parse_dependencies
    dependencies = {}

    podspec_files.each do |podspec_path|
      next unless File.exist?(podspec_path)

      module_name = File.basename(podspec_path, '.podspec')
      deps = extract_dependencies_from_podspec(podspec_path)
      dependencies[module_name] = deps
    end

    dependencies
  end

  # Build reverse dependency graph
  # Returns: { 'StripeCore' => ['StripeUICore', 'StripePayments', ...], ... }
  def build_reverse_dependencies(direct_deps)
    reverse = Hash.new { |h, k| h[k] = [] }

    direct_deps.each do |module_name, deps|
      deps.each do |dep|
        reverse[dep] << module_name
      end
    end

    # Ensure all modules have an entry
    direct_deps.keys.each { |mod| reverse[mod] ||= [] }

    reverse
  end

  def module_names
    @modules_yaml['modules'].map { |m| m['framework_name'] }
  end

  private

  def podspec_files
    @modules_yaml['modules'].map { |m| File.join(@repo_root, m['podspec']) }
  end

  # Extract dependencies by parsing the podspec file directly
  # This avoids loading CocoaPods which can be slow
  def extract_dependencies_from_podspec(podspec_path)
    content = File.read(podspec_path)
    deps = []

    # Match lines like: s.dependency 'StripeCore', s.version.to_s
    # or: s.dependency 'StripeCore'
    content.scan(/\.dependency\s+['"]([^'"]+)['"]/) do |match|
      dep_name = match[0]
      deps << dep_name if dep_name.start_with?('Stripe')
    end

    deps.uniq
  end
end

# ============================================================================
# Changed File Detection
# ============================================================================

class ChangedFileDetector
  def initialize(repo_root)
    @repo_root = repo_root
  end

  # Get list of changed files compared to origin/master
  def changed_files
    Dir.chdir(@repo_root) do
      current_branch = `git rev-parse --abbrev-ref HEAD`.strip

      if current_branch == 'master'
        puts 'On master branch - running all tests'
        return nil # Signal to run all tests
      end

      # Try to find merge base first (works with full clones)
      merge_base = `git merge-base origin/master HEAD 2>/dev/null`.strip

      if merge_base.empty? || !$?.success?
        # Shallow clone - compare directly against origin/master
        # This works because we fetch origin/master before running this script
        puts 'Using direct comparison to origin/master (shallow clone detected)'
        files = `git diff --diff-filter=AM --name-only origin/master HEAD 2>/dev/null`.split("\n")

        if !$?.success?
          warn 'Warning: Could not determine changed files. Running all tests.'
          return nil
        end

        return files
      end

      files = `git diff --diff-filter=AM --name-only "#{merge_base}"`.split("\n")
      files
    end
  end
end

# ============================================================================
# File to Module Mapper
# ============================================================================

class FileToModuleMapper
  def initialize(module_names)
    @module_names = module_names
  end

  # Map a file path to its owning module
  # Returns: module name or nil if not a module file
  def map_file_to_module(file_path)
    # Check for special mappings first
    DIRECTORY_TO_MODULE.each do |dir, mod|
      return mod if file_path.start_with?("#{dir}/")
    end

    # Standard module pattern: ModuleName/... -> ModuleName
    @module_names.each do |module_name|
      return module_name if file_path.start_with?("#{module_name}/")
    end

    # Handle legacy Stripe module (Stripe/StripeiOS/)
    return 'Stripe' if file_path.start_with?('Stripe/')

    nil
  end
end

# ============================================================================
# Test Selection Logic
# ============================================================================

class TestSelector
  def initialize(direct_deps, reverse_deps, mapper)
    @direct_deps = direct_deps
    @reverse_deps = reverse_deps
    @mapper = mapper
  end

  # Determine which modules need testing based on changed files
  # Returns: Set of module names to test, or :all if all tests should run
  def select_modules_to_test(changed_files)
    return :all if changed_files.nil?
    return :all if changed_files.empty? # No changes detected, run all as safety

    modules_to_test = Set.new

    changed_files.each do |file|
      # Check if this is a global trigger file
      if global_trigger_file?(file)
        puts "Global trigger file detected: #{file}"
        return :all
      end

      # Map file to module
      module_name = @mapper.map_file_to_module(file)
      next unless module_name

      # Add the directly affected module
      modules_to_test.add(module_name)

      # Add all downstream dependents (transitive)
      add_downstream_dependents(module_name, modules_to_test)
    end

    # If no modules detected from changes, run all as safety
    return :all if modules_to_test.empty?

    modules_to_test
  end

  private

  def global_trigger_file?(file_path)
    GLOBAL_TRIGGER_PATTERNS.any? { |pattern| file_path.match?(pattern) }
  end

  # Recursively add all modules that depend on the given module
  def add_downstream_dependents(module_name, result_set)
    dependents = @reverse_deps[module_name] || []

    dependents.each do |dependent|
      next if result_set.include?(dependent)

      result_set.add(dependent)
      add_downstream_dependents(dependent, result_set)
    end
  end
end

# ============================================================================
# Bitrise Environment Variable Output
# ============================================================================

class BitriseOutputter
  def initialize(all_modules)
    @all_modules = all_modules
  end

  # Output environment variables using envman
  def output_env_vars(modules_to_test)
    if modules_to_test == :all
      puts 'Running ALL tests (global changes detected or safety fallback)'
      set_all_modules(true)
    else
      puts "Selective testing: #{modules_to_test.to_a.sort.join(', ')}"
      set_selective_modules(modules_to_test)
    end
  end

  private

  def set_all_modules(value)
    @all_modules.each do |module_name|
      set_env_var(module_name, value)
    end
    # Also set a flag for 3DS2 tests (runs via fastlane)
    set_env_var('STRIPE3DS2', value)
  end

  def set_selective_modules(modules_to_test)
    @all_modules.each do |module_name|
      should_run = modules_to_test.include?(module_name)
      set_env_var(module_name, should_run)
    end

    # 3DS2 runs with StripePayments
    should_run_3ds2 = modules_to_test.include?('StripePayments')
    set_env_var('STRIPE3DS2', should_run_3ds2)
  end

  def set_env_var(module_name, value)
    # Normalize module name to uppercase env var
    env_name = "#{ENV_VAR_PREFIX}#{module_name.upcase}"
    env_value = value ? 'true' : 'false'

    puts "  #{env_name}=#{env_value}"

    # Use envman if available (Bitrise CI), otherwise just set ENV for local testing
    if system('which envman > /dev/null 2>&1')
      system("envman add --key #{env_name} --value \"#{env_value}\"")
    else
      ENV[env_name] = env_value
    end
  end
end

# ============================================================================
# Main Entry Point
# ============================================================================

def main
  repo_root = File.expand_path('..', __dir__)

  puts '=' * 60
  puts 'Determining which module tests to run...'
  puts '=' * 60
  puts ''

  # Parse dependencies from podspecs
  parser = DependencyParser.new(repo_root)
  direct_deps = parser.parse_dependencies
  reverse_deps = parser.build_reverse_dependencies(direct_deps)
  module_names = parser.module_names

  puts 'Module dependencies loaded:'
  direct_deps.each do |mod, deps|
    puts "  #{mod}: #{deps.empty? ? '(no deps)' : deps.join(', ')}"
  end
  puts ''

  # Detect changed files
  detector = ChangedFileDetector.new(repo_root)
  changed_files = detector.changed_files

  if changed_files
    puts "Changed files (#{changed_files.length}):"
    changed_files.each { |f| puts "  #{f}" }
    puts ''
  end

  # Map files to modules and select tests
  mapper = FileToModuleMapper.new(module_names)
  selector = TestSelector.new(direct_deps, reverse_deps, mapper)
  modules_to_test = selector.select_modules_to_test(changed_files)

  # Output environment variables
  puts '=' * 60
  puts 'Setting environment variables:'
  puts ''
  outputter = BitriseOutputter.new(module_names)
  outputter.output_env_vars(modules_to_test)
  puts ''
  puts '=' * 60
end

main if __FILE__ == $PROGRAM_NAME

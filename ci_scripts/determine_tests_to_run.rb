#!/usr/bin/env ruby
# frozen_string_literal: true

# Determines which module tests to run based on changed files.
# Sets RUN_MODULENAME=true/false environment variables for Bitrise.

require 'yaml'
require 'set'

REPO_ROOT = File.expand_path('..', __dir__)

GLOBAL_TRIGGERS = [
  /^ci_scripts\//,
  /^bitrise\.yml$/,
  /^Package\.swift$/,
  /^Gemfile/,
  /^\.swiftlint\.yml$/,
  /^BuildConfigurations\//,
  /^fastlane\//,
  /^Stripe\.xcworkspace\//,
  /^modules\.yaml$/,
  /^\.github\//,
  /^Brewfile$/,
  /^VERSION$/,
  /\.podspec$/,
  /^Tests\//,
  /^Testers\//,
  /^Example\//
].freeze

def load_modules_and_reverse_deps
  config = YAML.load_file(File.join(REPO_ROOT, 'modules.yaml'))
  modules = config['modules'].map { |m| m['framework_name'] }

  # Build reverse dependency graph from podspecs
  reverse_deps = Hash.new { |h, k| h[k] = [] }
  config['modules'].each do |m|
    podspec = File.join(REPO_ROOT, m['podspec'])
    next unless File.exist?(podspec)

    mod = m['framework_name']
    File.read(podspec).scan(/\.dependency\s+['"]([^'"]+)['"]/) do |match|
      dep = match[0]
      reverse_deps[dep] << mod if dep.start_with?('Stripe')
    end
  end

  [modules, reverse_deps]
end

def changed_files
  Dir.chdir(REPO_ROOT) do
    branch = `git rev-parse --abbrev-ref HEAD`.strip
    # Run all tests on master and release branches
    return nil if branch == 'master' || branch.start_with?('releases/')

    merge_base = `git merge-base origin/master HEAD 2>/dev/null`.strip
    if merge_base.empty? || !$?.success?
      files = `git diff --diff-filter=AM --name-only origin/master HEAD 2>/dev/null`.split("\n")
      return $?.success? ? files : nil
    end

    `git diff --diff-filter=AM --name-only "#{merge_base}"`.split("\n")
  end
end

def module_for_file(path, modules)
  return 'StripePayments' if path.start_with?('Stripe3DS2/') # 3DS2 and StripePayments are bundled together
  modules.find { |m| path.start_with?("#{m}/") } || ('Stripe' if path.start_with?('Stripe/'))
end

def add_dependents(mod, reverse_deps, result)
  (reverse_deps[mod] || []).each do |dep|
    next if result.include?(dep)
    result.add(dep)
    add_dependents(dep, reverse_deps, result)
  end
end

def modules_to_test(files, modules, reverse_deps)
  return :all if files.nil? || files.empty?

  result = Set.new
  files.each do |f|
    return :all if GLOBAL_TRIGGERS.any? { |t| f.match?(t) }

    mod = module_for_file(f, modules)
    next unless mod

    result.add(mod)
    add_dependents(mod, reverse_deps, result)
  end
  result
end

def set_env(name, value)
  val = value ? 'true' : 'false'
  puts "  #{name}=#{val}"
  if system('which envman > /dev/null 2>&1')
    system("envman add --key #{name} --value \"#{val}\"")
  else
    ENV[name] = val
  end
end

# Main
modules, reverse_deps = load_modules_and_reverse_deps
files = changed_files

puts "Changed files: #{files&.length || 'all (on master)'}"
files&.each { |f| puts "  #{f}" }

to_test = modules_to_test(files, modules, reverse_deps)
puts "\nSetting environment variables:"

modules.each { |m| set_env("RUN_#{m.upcase}", to_test == :all || to_test.include?(m)) }
# If StripePayments is included, we should also run 3DS2 tests
set_env('RUN_STRIPE3DS2', to_test == :all || to_test.include?('StripePayments'))
# TEMPORARY: PaymentSheet tests live in StripeTests, so run Stripe module if PaymentSheet changes
# TODO: Remove this once PaymentSheet tests are moved to their own module
if to_test != :all && to_test.include?('StripePaymentSheet')
  set_env('RUN_STRIPE', true)
end

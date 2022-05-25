#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'pathname'

skip_snapshot_tests = false
use_cache = false
build_scheme = nil
device = nil
version = nil
build_only = false
retry_tests = false
skip_tests = []
only_tests = []

OptionParser.new do |opts|
  opts.banner = "Testing tool for stripe-ios\n Usage: test.rb [options]"

  opts.on("--scheme [SCHEME]",
    "Build scheme (required) (stripe-ios, PaymentSheet Example, etc)") do |t|
    build_scheme = t
  end

  opts.on("--device [DEVICE]",
    "Device to run tests on (iPhone 8, iPhone 11, etc)") do |t|
    device = t
  end

  opts.on("--version [VERSION]",
    "OS version to run tests on (13.7, 14.2, etc)") do |t|
    version = t
  end

  opts.on("--only-test [TEST1,TEST2,TEST3]", Array,
    "List of tests to run") do |t|
    only_tests = t
  end

  opts.on("--skip-test [TEST1,TEST2,TEST3]", Array,
    "List of tests to exclude") do |t|
    skip_tests = t
  end

  opts.on("--skip-snapshot-tests", "Don't run snapshot tests") do |s|
    skip_snapshot_tests = s
  end

  opts.on("--cache", "Use cached tests") do |s|
    use_cache = s
  end

  opts.on("--build-only", "Only build and cache the tests, don't run them.") do |s|
    build_only = s
  end

  opts.on("--retry-on-failure", "Retry tests on failure") do |s|
    retry_tests = s
  end
end.parse!

if build_scheme.nil?
  puts 'You must specify a build scheme.'
  exit 1
end

# Given a path to a test file, this method will return the test target
# and name of the test.
def infer_test_target_and_name(path)
  pathname = Pathname.new(path)

  # Find first folder that ends with 'Tests'.
  test_dir = pathname.each_filename.detect { |f| f.end_with?('Tests') }

  # Skip if no 'Tests' folder is found.
  return if test_dir.nil?

  # Target and folder name for the `Stripe` module don't follow the new
  # naming convention. This conditional can be removed once we migrate it.
  test_target = test_dir == 'Tests' ? 'StripeiOS Tests' : test_dir
  test_name = File.basename(path, '.*')

  "#{test_target}/#{test_name}"
end

# Discovers and returns the list of snapshot tests across all modules.
def discover_snapshot_tests
  tests = []

  files = Dir.glob('**/*Snapshot{Test,Tests}.{swift,m}')

  files.each do |path|
    test = infer_test_target_and_name(path)
    tests << test unless test.nil?
  end

  tests.sort
end

if skip_snapshot_tests
  skip_tests += [
    # Subset of tests that don't end with 'Snapshot(Test|Tests)'.
    'StripeiOS Tests/STPAddCardViewControllerLocalizationTests',
    'StripeiOS Tests/STPPaymentOptionsViewControllerLocalizationTests',
    'StripeiOS Tests/STPShippingAddressViewControllerLocalizationTests',
    'StripeiOS Tests/STPShippingMethodsViewControllerLocalizationTests'
  ]

  skip_tests += discover_snapshot_tests()
end

destination_string = 'generic/platform=iOS Simulator'
build_action = 'test'

if build_only
  # We'll want to clean outside this script.
  # If we clean here, we may unintentionally throw out the cache we built for other targets!
  build_action = 'build-for-testing'
else
  if use_cache
    if File.exist?(__dir__ + '/../build-ci-tests/' + build_scheme + '.finished')
      build_action = 'test-without-building'
    end
  end
  if !device.nil? && !version.nil?
    destination_string = 'platform=iOS Simulator'
    destination_string += ',name=' + device
    destination_string += ',OS=' + version
  end
end

skip_tests_command = ""
for skip_test in skip_tests
  skip_tests_command += "-skip-testing:\"#{skip_test}\" "
end

only_tests_command = ""
for only_test in only_tests
  only_tests_command += "-only-testing:\"#{only_test}\" "
end

quiet_command = ""

quiet_command = "-quiet" if build_action == 'build-for-testing'

retry_tests_command = ""

retry_tests_command = "-retry-tests-on-failure -test-iterations 5" if retry_tests

Dir.chdir(__dir__ + '/..') do
  carthage_command = <<~HEREDOC
    carthage bootstrap --platform iOS --configuration Release --no-use-binaries --cache-builds --use-xcframeworks
  HEREDOC
  puts carthage_command
  system carthage_command
  exit $?.exitstatus unless $?.success?

  xcodebuild_command = <<~HEREDOC
    xcodebuild #{build_action} \
    #{quiet_command} \
    -workspace "Stripe.xcworkspace" \
    -scheme "#{build_scheme}" \
    -configuration "Debug" \
    -sdk "iphonesimulator" \
    -destination "#{destination_string}" \
    -derivedDataPath build-ci-tests \
    #{skip_tests_command} \
    #{only_tests_command} \
    #{retry_tests_command}
  HEREDOC
  puts xcodebuild_command
  system xcodebuild_command
  exit $?.exitstatus unless $?.success?

  if build_only
    # If the build succeeded, create a placeholder cache key for the target.
    FileUtils.touch(__dir__ + '/../build-ci-tests/' + build_scheme + '.finished')
  end
end

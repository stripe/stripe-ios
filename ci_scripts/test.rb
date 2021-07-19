#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

skip_snapshot_tests = false
use_cache = true
build_scheme = nil
device = nil
version = nil
build_only = false
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

  opts.on("--no-cache", "Don't use cached tests") do |s|
    use_cache = !s
  end

  opts.on("--build-only", "Only build and cache the tests, don't run them.") do |s|
    build_only = s
  end
end.parse!

if build_scheme.nil?
  puts 'You must specify a build scheme.'
  exit 1
end

if skip_snapshot_tests
  skip_tests += [
    "StripeiOS Tests/STPAddCardViewControllerLocalizationTests",
    "StripeiOS Tests/STPPaymentOptionsViewControllerLocalizationTests",
    "StripeiOS Tests/STPShippingAddressViewControllerLocalizationTests",
    "StripeiOS Tests/STPShippingMethodsViewControllerLocalizationTests",
    "StripeiOS Tests/STPAUBECSDebitFormViewSnapshotTests",
    "StripeiOS Tests/STPPaymentContextSnapshotTests",
    "StripeiOS Tests/STPSTPViewWithSeparatorSnapshotTests",
    "StripeiOS Tests/STPLabeledFormTextFieldViewSnapshotTests",
    "StripeiOS Tests/STPLabeledMultiFormTextFieldViewSnapshotTests",
    "StripeiOS Tests/STPFloatingPlaceholderTextFieldSnapshotTests",
    "StripeiOS Tests/STPCardCVCInputTextFieldSnapshotTests",
    "StripeiOS Tests/STPCardExpiryInputTextFieldSnapshotTests",
    "StripeiOS Tests/STPCardFormViewSnapshotTests",
    "StripeiOS Tests/STPCardNumberInputTextFieldSnapshotTests",
    "StripeiOS Tests/STPFormViewSnapshotTests",
    "StripeiOS Tests/STPStackViewWithSeparatorTests",
    "StripeiOS Tests/STPPostalCodeInputTextFieldSnapshotTests",
    "StripeiOS Tests/STPCountryPickerInputFieldSnapshotTests",
    "StripeiOS Tests/STPGenericInputTextFieldSnapshotTests",
    "StripeiOS Tests/STPGenericInputPickerFieldSnapshotTests",
    "StripeiOS Tests/STPiDEALBankPickerInputFieldSnapshotTests",
    "StripeiOS Tests/STPiDEALFormViewSnapshotTests",
    "StripeiOS Tests/AfterpayPriceBreakdownViewSnapshotTests",
    "StripeIdentityTests/VerificationFlowWebViewSnapshotTests"
  ]
end

destination_string = 'generic/platform=iOS Simulator'
build_action = 'clean test'

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
    #{only_tests_command}
  HEREDOC
  puts xcodebuild_command
  system xcodebuild_command
  exit $?.exitstatus unless $?.success?

  if build_only
    # If the build succeeded, create a placeholder cache key for the target.
    FileUtils.touch(__dir__ + '/../build-ci-tests/' + build_scheme + '.finished')
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

# run_tests.rb — Unified test runner for stripe-ios local development.
# Handles simulator setup, scheme resolution, and xcodebuild invocation.

require "optparse"
require "shellwords"

REPO_ROOT = File.expand_path("..", __dir__)

# --- Target-to-Scheme lookup ---
TARGET_TO_SCHEME = {
  "StripePaymentSheetTests"          => "StripePaymentSheet",
  "StripeCoreTests"                  => "StripeCore",
  "StripeUICoreTests"                => "StripeUICore",
  "StripePaymentsTests"              => "StripePayments",
  "StripePaymentsUITests"            => "StripePaymentsUI",
  "StripeApplePayTests"              => "StripeApplePay",
  "StripeIdentityTests"              => "StripeIdentity",
  "StripeFinancialConnectionsTests"  => "StripeFinancialConnections",
  "StripeConnectTests"               => "StripeConnect",
  "StripeCardScanTests"              => "StripeCardScan",
  "Stripe3DS2Tests"                  => "Stripe3DS2",
  "StripeCameraCoreTests"            => "StripeCameraCore",
  "StripeCryptoOnrampTests"          => "StripeCryptoOnramp",
  "StripeiOS Tests"                  => "StripeiOS",
  "StripeiOSTests"                   => "StripeiOS",
  "PaymentSheetUITest"               => "PaymentSheet Example",
}.freeze

# --- Options ---
options = {
  scheme: nil,
  all: false,
  ui: false,
  record_snapshots: false,
  record_network: false,
  retry: false,
  build_only: false,
  verbose: false,
  dry_run: false,
  tests: [],
  skip_tests: [],
}

# --- Argument parsing ---
banner = <<~USAGE
  Usage: ci_scripts/run_tests.rb [OPTIONS]

  Examples:
    ci_scripts/run_tests.rb --test StripeCoreTests/STPLocalizationUtilsTest/testAllStringsAreTranslated
    ci_scripts/run_tests.rb --scheme StripePaymentSheet
    ci_scripts/run_tests.rb --all
    ci_scripts/run_tests.rb --record-snapshots --test StripePaymentSheetTests/SomeSnapshotTest
    ci_scripts/run_tests.rb --record-network --test StripePaymentsTests/STPCardFunctionalTest
    ci_scripts/run_tests.rb --ui
    ci_scripts/run_tests.rb --scheme StripeCore --retry
    ci_scripts/run_tests.rb --scheme StripeCore --dry-run

USAGE

parser = OptionParser.new do |opts|
  opts.banner = banner

  opts.on("--scheme NAME", "Run tests for a specific scheme (e.g. StripePaymentSheet)") do |v|
    options[:scheme] = v
  end
  opts.on("--all", "Run all framework tests (AllStripeFrameworks)") do
    options[:all] = true
  end
  opts.on("--test SPECIFIER", "Run specific test(s). Repeatable. Format: TestTarget/TestClass/testMethod") do |v|
    options[:tests] << v
  end
  opts.on("--skip-test SPECIFIER", "Skip specific test(s). Repeatable.") do |v|
    options[:skip_tests] << v
  end
  opts.on("--ui", "Run UI tests (PaymentSheet Example scheme)") do
    options[:ui] = true
  end
  opts.on("--record-snapshots", "Record snapshot reference images (RecordMode scheme)") do
    options[:record_snapshots] = true
  end
  opts.on("--record-network", "Record network responses (NetworkRecordMode scheme)") do
    options[:record_network] = true
  end
  opts.on("--retry", "Retry failed tests up to 5 times") do
    options[:retry] = true
  end
  opts.on("--build-only", "Build without running tests") do
    options[:build_only] = true
  end
  opts.on("--verbose", "Show full xcodebuild output (default is quiet)") do
    options[:verbose] = true
  end
  opts.on("--dry-run", "Print the xcodebuild command without executing") do
    options[:dry_run] = true
  end
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit 0
  end
end

if ARGV.empty?
  puts parser
  exit 0
end

begin
  parser.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  abort "Error: #{e.message}\nRun with --help for usage information."
end

unless ARGV.empty?
  abort "Error: unexpected argument(s): #{ARGV.join(" ")}\nRun with --help for usage information."
end

# --- Validate flag conflicts ---
if options[:record_snapshots] && options[:record_network]
  abort "Error: --record-snapshots and --record-network cannot be used together."
end

if options[:ui] && (options[:record_snapshots] || options[:record_network])
  abort "Error: --ui cannot be combined with --record-snapshots or --record-network."
end

# --- Resolve scheme ---
scheme =
  if options[:record_snapshots]
    warn "Warning: --record-snapshots overrides --scheme. Using AllStripeFrameworks-RecordMode." if options[:scheme]
    "AllStripeFrameworks-RecordMode"
  elsif options[:record_network]
    warn "Warning: --record-network overrides --scheme. Using AllStripeFrameworks-NetworkRecordMode." if options[:scheme]
    "AllStripeFrameworks-NetworkRecordMode"
  elsif options[:ui]
    "PaymentSheet Example"
  elsif options[:all]
    "AllStripeFrameworks"
  elsif options[:scheme]
    options[:scheme]
  elsif !options[:tests].empty?
    first_target = options[:tests].first.split("/").first
    inferred = TARGET_TO_SCHEME[first_target]
    unless inferred
      warn "Warning: Could not infer scheme from target '#{first_target}'. Using AllStripeFrameworks."
    end
    inferred || "AllStripeFrameworks"
  else
    abort "Error: No scheme, --all, --ui, --test, or recording mode specified.\nRun with --help for usage information."
  end

# --- Setup simulator ---
Dir.chdir(REPO_ROOT)

# Source setup_simulator.sh and capture the exported DEVICE_ID_FROM_USER_SETTINGS
device_id = ENV["DEVICE_ID_FROM_USER_SETTINGS"]
unless device_id && !device_id.empty?
  # Run setup_simulator.sh in a subshell that prints the device ID
  device_id = `bash -c 'source ci_scripts/setup_simulator.sh && echo "$DEVICE_ID_FROM_USER_SETTINGS"'`.strip
  if device_id.empty? || !$?.success?
    abort "Error: Simulator setup failed. DEVICE_ID_FROM_USER_SETTINGS is not set.\n" \
          "Try: ./ci_scripts/setup_simulator.sh --clear-cache && source ci_scripts/setup_simulator.sh"
  end
end

# Boot the simulator (ignore error if already booted)
system("xcrun", "simctl", "boot", device_id, err: File::NULL, out: File::NULL)

# --- Build xcodebuild command ---
action = options[:build_only] ? "build-for-testing" : "test"

cmd = [
  "xcodebuild",
  action,
  "-workspace", "Stripe.xcworkspace",
  "-scheme", scheme,
  "-destination", "id=#{device_id},arch=arm64",
]

cmd << "-quiet" unless options[:verbose]

cmd += %w[SWIFT_SUPPRESS_WARNINGS=YES SWIFT_TREAT_WARNINGS_AS_ERRORS=NO]

options[:tests].each { |spec| cmd << "-only-testing:#{spec}" }
options[:skip_tests].each { |spec| cmd << "-skip-testing:#{spec}" }

if options[:retry]
  cmd += %w[-retry-tests-on-failure -test-iterations 5]
end

# --- Recording mode note ---
if options[:record_snapshots] || options[:record_network]
  puts "Note: Tests are expected to fail in recording mode."
end

# --- Execute ---
puts "Scheme: #{scheme}"

if options[:dry_run]
  puts "[dry-run] #{cmd.shelljoin}"
  exit 0
end

puts "Running: #{cmd.shelljoin}"
exec(*cmd)

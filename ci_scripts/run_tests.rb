#!/usr/bin/env ruby
# frozen_string_literal: true

# run_tests.rb — Unified test runner for stripe-ios local development.
# Handles simulator setup, scheme resolution, and xcodebuild invocation.

require "optparse"
require "shellwords"
require "json"
require "fileutils"

REPO_ROOT = File.expand_path("..", __dir__)
DEFAULT_RESULT_BUNDLE = "/tmp/stripe-ios-test-results.xcresult"
DEFAULT_FAILURE_SCREENSHOTS = "/tmp/stripe-ios-failure-screenshots"

# --- Failure inspection ---
def inspect_failures(xcresult_path)
  puts "Inspecting: #{xcresult_path}\n\n"

  # 1. Summary
  summary_json = `xcrun xcresulttool get test-results summary --path #{xcresult_path.shellescape} 2>/dev/null`
  if $?.success? && !summary_json.strip.empty?
    summary = JSON.parse(summary_json) rescue nil
    if summary
      puts "=== Test Summary ==="
      puts "Result: #{summary["result"] || "unknown"}"
      if summary["totalTestCount"]
        puts "Total tests: #{summary["totalTestCount"]}"
        puts "  Passed: #{summary["passedTests"] || 0}"
        puts "  Failed: #{summary["failedTests"] || 0}"
        puts "  Skipped: #{summary["skippedTests"] || 0}"
      end
      failures = summary["testFailures"] || []
      if failures.any?
        puts "\n=== Failure Messages ==="
        failures.each do |f|
          test_name = f["testName"] || f["testIdentifier"] || "unknown test"
          message = f["message"] || f["failureText"] || "no message"
          puts "  FAIL: #{test_name}"
          puts "        #{message}"
          puts
        end
      end
    end
  else
    puts "Warning: Could not read test summary from xcresult."
  end

  # 2. Failed test list
  tests_json = `xcrun xcresulttool get test-results tests --path #{xcresult_path.shellescape} 2>/dev/null`
  if $?.success? && !tests_json.strip.empty?
    tests_data = JSON.parse(tests_json) rescue nil
    if tests_data
      failed_tests = []
      collect_failed = lambda do |nodes, path_parts|
        (nodes || []).each do |node|
          current_path = path_parts + [node["name"] || ""]
          if node["nodeType"] == "Test Case" && node["result"] == "Failed"
            failed_tests << current_path.join("/")
          end
          collect_failed.call(node["children"], current_path) if node["children"]
        end
      end
      collect_failed.call(tests_data["testNodes"], [])
      if failed_tests.any?
        puts "=== Failed Tests ==="
        failed_tests.each { |t| puts "  #{t}" }
        puts "\nRe-run failed tests with:"
        failed_tests.each { |t| puts "  ci_scripts/run_tests.rb --test #{t}" }
        puts
      end
    end
  end

  # 3. Export failure screenshots
  export_dir = DEFAULT_FAILURE_SCREENSHOTS
  FileUtils.rm_rf(export_dir) if File.exist?(export_dir)
  FileUtils.mkdir_p(export_dir)
  system("xcrun", "xcresulttool", "export", "attachments",
         "--path", xcresult_path,
         "--output-path", export_dir,
         "--only-failures",
         out: File::NULL, err: File::NULL)
  manifest_path = File.join(export_dir, "manifest.json")
  if File.exist?(manifest_path)
    manifest = JSON.parse(File.read(manifest_path)) rescue nil
    if manifest
      files = manifest.flat_map { |entry| entry["exportedFiles"] || [] }
                      .map { |f| File.join(export_dir, f["fileName"]) }
                      .select { |f| File.exist?(f) }
      if files.any?
        puts "=== Failure Screenshots ==="
        puts "Exported #{files.size} attachment(s) to #{export_dir}:"
        files.each { |f| puts "  #{f}" }
        puts
      end
    end
  end
end

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
  result_bundle_path: DEFAULT_RESULT_BUNDLE,
  failures: nil,
}

# --- Argument parsing ---
banner = <<~USAGE
  Usage: ci_scripts/run_tests.rb [OPTIONS]

  Examples:
    ci_scripts/run_tests.rb --test StripeCoreTests/URLEncoderTest/testQueryStringFromParameters
    ci_scripts/run_tests.rb --scheme StripePaymentSheet
    ci_scripts/run_tests.rb --all
    ci_scripts/run_tests.rb --record-snapshots --test StripePaymentSheetTests/SomeSnapshotTest
    ci_scripts/run_tests.rb --record-network --test StripePaymentsTests/STPCardFunctionalTest
    ci_scripts/run_tests.rb --ui
    ci_scripts/run_tests.rb --scheme StripeCore --retry
    ci_scripts/run_tests.rb --scheme StripeCore --dry-run
    ci_scripts/run_tests.rb --failures                      # Inspect last test run
    ci_scripts/run_tests.rb --failures /path/to/result.xcresult

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
  opts.on("--result-bundle-path PATH", "Path for xcresult bundle (default: #{DEFAULT_RESULT_BUNDLE})") do |v|
    options[:result_bundle_path] = v
  end
  opts.on("--failures [PATH]", "Inspect failures from xcresult bundle (default: last run)") do |v|
    options[:failures] = v || options[:result_bundle_path]
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

# --- Failure inspection mode (early exit) ---
if options[:failures]
  Dir.chdir(REPO_ROOT)
  unless File.exist?(options[:failures])
    abort "Error: xcresult not found at #{options[:failures]}\n" \
          "Run tests first, or specify path: --failures /path/to/result.xcresult"
  end
  inspect_failures(options[:failures])
  exit 0
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

cmd << "-resultBundlePath" << options[:result_bundle_path]

if options[:dry_run]
  puts "[dry-run] #{cmd.shelljoin}"
  exit 0
end

FileUtils.rm_rf(options[:result_bundle_path]) if File.exist?(options[:result_bundle_path])

puts "Running: #{cmd.shelljoin}"
puts "Result bundle: #{options[:result_bundle_path]}"
success = system(*cmd)
unless success
  exit_code = $?.exitstatus || 1
  puts "\nTests failed! Inspect failures with:"
  puts "  ci_scripts/run_tests.rb --failures"
  exit exit_code
end

# --- Verify tests actually ran ---
unless options[:build_only]
  result_path = options[:result_bundle_path]
  if File.exist?(result_path)
    summary_json = `xcrun xcresulttool get test-results summary --path #{result_path.shellescape} 2>/dev/null`
    if $?.success? && !summary_json.strip.empty?
      summary = JSON.parse(summary_json) rescue nil
      if summary
        total = summary["totalTestCount"].to_i
        if total == 0
          abort "Error: 0 tests were executed. The test specifier may not match any tests.\n" \
                "Check your --test argument and ensure the target/class/method names are correct."
        end
        puts "#{total} test(s) executed."
      end
    end
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'open3'
require 'json'

# ============================================================================
# DATA COLLECTION - These functions run tests and parse output
# ============================================================================

# Merges test results from source into target hash
def merge_results(target, source)
  target.merge!(source) { |_, old, new| old + new }
end

#
# Returns a hash mapping test names to arrays of durations:
#   {
#     "-[MPELatencyTest testLoadLatency]" => [0.2358, 0.2490, 0.2423, ...],
#     "testDefaultConfiguration" => [0.3123, 0.3087, ...]
#   }
def run_latency_tests_for_commit(commit, iterations)
  puts "\n" + "=" * 80
  puts "Testing commit: #{commit}"
  puts "=" * 80

  # Checkout the commit
  puts "Checking out commit #{commit}..."
  unless system("git checkout #{commit} 2>&1")
    puts "Error: Failed to checkout commit #{commit}"
    exit 1
  end

  # Run the tests
  puts "Running latency tests (#{iterations} iterations)..."
  output = run_xcodebuild_tests(iterations)

  # Parse the results
  results = parse_latency_results(output)

  puts "Found #{results.length} test(s) with results"

  results
end

# Runs the xcodebuild test command and captures output
def run_xcodebuild_tests(iterations)
  # Create a temporary directory for the result bundle
  result_bundle_path = File.join(Dir.pwd, "test_results_#{Time.now.to_i}.xcresult")

  command = <<~CMD.gsub("\n", " ").strip
    source ci_scripts/setup_simulator.sh &&
    xcodebuild test
    -scheme StripePaymentSheet-LatencyTests
    -workspace Stripe.xcworkspace
    -destination "id=$DEVICE_ID_FROM_USER_SETTINGS,arch=arm64"
    -test-iterations #{iterations}
    -resultBundlePath #{result_bundle_path} # we use this to extract the prints from the test log
    SWIFT_SUPPRESS_WARNINGS=YES
    SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
  CMD

  # Execute command and capture output while displaying it
  output = ""
  
  Open3.popen2e("bash", "-c", command) do |stdin, stdout_stderr, wait_thread|
    stdin.close
    stdout_stderr.each_line do |line|
      print line  # Display in real-time
      output += line  # Capture for parsing
    end

    exit_status = wait_thread.value
    unless exit_status.success?
      puts "\nWarning: xcodebuild command exited with status #{exit_status.exitstatus}"
      puts "Continuing to parse available output..."
    end
  end

  # Extract test logs from the result bundle
  if File.exist?(result_bundle_path)
    puts "\nExtracting test logs from result bundle..."
    log_output = extract_logs_from_xcresult(result_bundle_path)
    output += "\n" + log_output

    # Clean up result bundle
    FileUtils.rm_rf(result_bundle_path)
  end

  output
end

# Extracts test logs from xcresult bundle
def extract_logs_from_xcresult(result_bundle_path)
  # Use xcrun to extract the logs
  log_command = "xcrun xcresulttool get --path '#{result_bundle_path}' --format json"
  json_output = `#{log_command} 2>&1`

  # Also try to get the test logs specifically
  logs_command = "xcrun xcresulttool get --path '#{result_bundle_path}' --id root 2>&1 | grep -A 5 -B 5 'SYNTHETIC_LATENCY_RESULT' || echo ''"
  logs = `bash -c "#{logs_command}"`

  # Alternative: export as text
  text_command = "xcrun xcresulttool get --path '#{result_bundle_path}' --format json 2>&1"
  text_output = `#{text_command}`

  # Return combined output
  [json_output, logs, text_output].join("\n")
end

# Parses test output to extract SYNTHETIC_LATENCY_RESULT lines.
#
# Returns a hash mapping test names to arrays of durations:
#   {
#     "-[MPELatencyTest testLoadLatency]" => [0.2358, 0.2490],
#     "testDefaultConfiguration" => [0.3123, 0.3087]
#   }
def parse_latency_results(output)
  results = Hash.new { |h, k| h[k] = [] }

  output.each_line do |line|
    # Match lines like:
    # SYNTHETIC_LATENCY_RESULT: testDefaultConfiguration: 0.235843476345
    # SYNTHETIC_LATENCY_RESULT: -[MPELatencyTest testLoadLatency]: 0.235843476345
    # or any format with a test name and duration
    if line =~ /SYNTHETIC_LATENCY_RESULT:\s*(.+?):\s*([\d.]+)/
      test_name = $1.strip
      duration = $2.to_f
      results[test_name] << duration
      puts "  Found result: #{test_name} = #{duration}s"
    end
  end

  results
end

# ============================================================================
# STATISTICAL CALCULATIONS - Pure functions that return data structures
# ============================================================================

# t-distribution critical values for 95% CI (two-tailed, alpha=0.05)
# Key: degrees of freedom, Value: t-critical
T_CRITICAL_VALUES = {
  1 => 12.706, 2 => 4.303, 3 => 3.182, 4 => 2.776, 5 => 2.571,
  6 => 2.447, 7 => 2.365, 8 => 2.306, 9 => 2.262, 10 => 2.228,
  11 => 2.201, 12 => 2.179, 13 => 2.160, 14 => 2.145, 15 => 2.131,
  16 => 2.120, 17 => 2.110, 18 => 2.101, 19 => 2.093, 20 => 2.086,
  25 => 2.060, 30 => 2.042
}.freeze

# Gets t-critical value for 95% CI given degrees of freedom
def get_t_critical(df)
  return T_CRITICAL_VALUES[df] if T_CRITICAL_VALUES.key?(df)
  # For large samples, use normal approximation
  df >= 30 ? 1.96 : T_CRITICAL_VALUES[30]
end

# Calculates mean of an array
def mean(array)
  array.sum / array.length.to_f
end

# Calculates standard deviation with Bessel's correction (n-1)
def standard_deviation(array, mean_val)
  variance = array.map { |x| (x - mean_val) ** 2 }.sum / (array.length - 1).to_f
  Math.sqrt(variance)
end

# Computes paired statistics comparing new commit to base commit.
#
# Returns a hash with statistical measures:
#   {
#     abs_mean: 0.023,      # Mean absolute difference in seconds (new - base)
#     abs_margin: 0.005,    # 95% CI margin in seconds (±)
#     pct_mean: 8.3,        # Mean percentage difference ((new - base) / base * 100)
#     pct_margin: 1.2,      # 95% CI margin in percentage points (±)
#     n: 10,                # Number of paired observations
#     significant: true     # Whether the difference is statistically significant (p < 0.05)
#   }
#
# Returns nil if insufficient data (n < 2)
def compute_paired_statistics(base_values, new_values)
  # Compute paired differences
  abs_diffs = base_values.zip(new_values).map { |base, new| new - base }
  pct_diffs = base_values.zip(new_values).map { |base, new| (new - base) / base * 100.0 }

  # Calculate statistics for absolute differences
  n = base_values.length
  abs_mean = mean(abs_diffs)
  abs_sd = standard_deviation(abs_diffs, abs_mean)
  abs_se = abs_sd / Math.sqrt(n)
  abs_margin = get_t_critical(n - 1) * abs_se

  # Calculate statistics for percentage differences
  pct_mean = mean(pct_diffs)
  pct_sd = standard_deviation(pct_diffs, pct_mean)
  pct_se = pct_sd / Math.sqrt(n)
  pct_margin = get_t_critical(n - 1) * pct_se

  # Calculate statistical significance
  # If the percentage difference (e.g. -10%) is greater than the margin of error, then the result is statistically significant (p < 0.05)
  significant = pct_mean.abs > pct_margin

  {
    abs_mean: abs_mean,
    abs_margin: abs_margin,
    pct_mean: pct_mean,
    pct_margin: pct_margin,
    n: n,
    significant: significant
  }
end

# Computes statistical analysis for all tests comparing commits.
# Expects all_results to have :base and :new keys with test results.
#
# Returns a hash mapping test names to statistics on the *difference* between new and base:
#   {
#     "testLoadLatency" => {
#       abs_mean: 0.023,    # The mean absolute difference in seconds (new - base)
#       abs_margin: 0.005,  # The 95% CI margin in seconds (±)
#       pct_mean: 8.3,      # The mean percentage difference ((new - base) / base * 100)
#       pct_margin: 1.2,    # The 95% CI margin in percentage points (±)
#       n: 10,              # Number of paired observations
#       significant: true   # Whether the difference is statistically significant (p < 0.05)
#     }
#   }
#
def compute_statistical_report(all_results)
  base_tests = all_results[:base] # Looks like { "test name" -> [1, 2, 3] }
  new_tests = all_results[:new]

  raise "No test results found for one or both commits" if base_tests.empty? || new_tests.empty?

  # Find common tests between base and new
  common_tests = base_tests.keys & new_tests.keys
  raise "No common tests found between commits" if common_tests.empty?

  # Calculate statistics for each test
  test_stats = {}
  for test_name in common_tests
    base_values = base_tests[test_name]
    new_values = new_tests[test_name]

    # Validate that we have the same number of measurements for paired comparison
    raise "Test '#{test_name}' has mismatched iteration counts: base=#{base_values.length}, new=#{new_values.length}" unless base_values.length == new_values.length

    # Compute stats for the given test
    stats = compute_paired_statistics(base_values, new_values)
    test_stats[test_name] = stats if stats
  end

  test_stats
end

# ============================================================================
# PRINTING - Functions that format and display results
# ============================================================================

# Prints raw latency measurements for both commits
# all_results uses :base and :new as keys
# base_commit and new_commit are the actual commit hashes for display
def print_raw_measurements(all_results, base_commit, new_commit)
  puts "\n" + "=" * 80
  puts "RAW LATENCY MEASUREMENTS"
  puts "=" * 80

  # Base commit
  puts "\nBase Commit: #{base_commit}"
  puts "-" * 80
  all_results[:base].each do |test_name, durations|
    avg = durations.sum / durations.length
    puts "  #{test_name}:"
    puts "    Runs: #{durations.map { |d| "%.4fs" % d }.join(", ")}"
    puts "    Average: %.4fs" % avg
  end

  # New commit
  puts "\nNew Commit: #{new_commit}"
  puts "-" * 80
  all_results[:new].each do |test_name, durations|
    avg = durations.sum / durations.length
    puts "  #{test_name}:"
    puts "    Runs: #{durations.map { |d| "%.4fs" % d }.join(", ")}"
    puts "    Average: %.4fs" % avg
  end
end

# Prints the statistical delta report table
def print_statistical_report(test_stats, all_results)
  puts "\n" + "=" * 80
  puts "LATENCY DELTA REPORT (vs Base Commit)"
  puts "=" * 80

  if test_stats.nil? || test_stats.empty?
    puts "Error: No test results found for comparison"
    return
  end

  # Calculate dynamic column width for test names (minimum 40 characters)
  max_test_name_length = [test_stats.keys.map(&:length).max, 40].max

  # Calculate total table width
  base_width = 13
  new_width = 12
  delta_width = 45
  significance_width = 20
  separators = 12  # " | " separators (3 chars each * 4)
  total_width = max_test_name_length + base_width + new_width + delta_width + significance_width + separators

  # Print table header
  puts ""
  puts sprintf("%-#{max_test_name_length}s | %#{base_width}s | %#{new_width}s | %-#{delta_width}s | %s", "Test", "Base commit", "New commit", "Mean Delta (95% CI)", "Significant Difference?")
  puts "-" * total_width

  # Print results for each test
  test_stats.sort.each do |test_name, stats|
    base_avg = mean(all_results[:base][test_name]) * 1000  # Convert to ms
    new_avg = mean(all_results[:new][test_name]) * 1000    # Convert to ms

    # Format: Δ -8.3% ± 3%; -120ms ± 38ms
    pct_str = sprintf("Δ %+.1f%% ± %.1f%%", stats[:pct_mean], stats[:pct_margin])
    abs_str = sprintf("%+.0fms ± %.0fms", stats[:abs_mean] * 1000, stats[:abs_margin] * 1000)
    delta_str = "#{pct_str}; #{abs_str}"

    significance_str = stats[:significant] ? "✅ Yes (p < 0.05)" : "No"

    puts sprintf("%-#{max_test_name_length}s | %#{base_width}s | %#{new_width}s | %-#{delta_width}s | %s", test_name, "%.0fms" % base_avg, "%.0fms" % new_avg, delta_str, significance_str)
  end

  puts ""
end

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Parse command-line arguments
options = {
  iterations: 20  # Default value
}

OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage: measure_latency_difference.rb [options]

    Measures and compares iOS app latency between two git commits.

    This script:
    1. Checks out each commit and runs StripePaymentSheet latency tests multiple times
    2. Parses SYNTHETIC_LATENCY_RESULT output from test logs
    3. Performs paired t-test analysis to compare latency differences
    4. Reports mean delta with 95% confidence intervals and statistical significance (p < 0.05)

    Examples:
      # Compare two different commits
      ./measure_latency_difference.rb --base-commit abc123 --commit def456

      # A/A test (same commit twice to verify no false positives)
      ./measure_latency_difference.rb --base-commit abc123 --commit abc123

    Options:
  BANNER

  opts.on("--base-commit COMMIT", "Base commit to compare against (required)") do |commit|
    options[:base_commit] = commit
  end

  opts.on("--commit COMMIT", "New commit to compare (required)") do |commit|
    options[:commit] = commit
  end

  opts.on("--iterations N", Integer, "Number of test iterations to run (default: 20)") do |n|
    options[:iterations] = n
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

# Validate required arguments
if options[:base_commit].nil? || options[:commit].nil?
  puts "Error: --base-commit and --commit are required"
  puts "Run with --help for usage information"
  exit 1
end

# Main execution
puts "Configuration:"
puts "  Base commit: #{options[:base_commit]}"
puts "  New commit:  #{options[:commit]}"
puts "  Iterations:  #{options[:iterations]}"

# Store original branch to restore later
original_branch = `git rev-parse --abbrev-ref HEAD`.strip
puts "  Current branch: #{original_branch}"

# ============================================================================
# STEP 1: COLLECT DATA - Run tests for both commits
# ============================================================================
# Use symbol keys (:base, :new) to avoid hash collision when commits are identical (A/A test)
all_results = { base: {}, new: {} }

if options[:iterations] >= 10
  # Use ABBA ordering to reduce temporal bias (thermal throttling, background processes, etc.)
  run_size = options[:iterations] / 2

  puts "\nUsing ABBA ordering (#{run_size} iterations × 4 runs = #{run_size * 4} total iterations per commit)"

  merge_results(all_results[:base], run_latency_tests_for_commit(options[:base_commit], run_size))  # A
  merge_results(all_results[:new], run_latency_tests_for_commit(options[:commit], run_size))        # B
  merge_results(all_results[:new], run_latency_tests_for_commit(options[:commit], run_size))        # B
  merge_results(all_results[:base], run_latency_tests_for_commit(options[:base_commit], run_size))  # A
else
  # Use sequential approach for small iteration counts
  puts "\nUsing sequential testing (#{options[:iterations]} iterations each)"
  all_results[:base] = run_latency_tests_for_commit(options[:base_commit], options[:iterations])
  all_results[:new] = run_latency_tests_for_commit(options[:commit], options[:iterations])
end

# all_results data structure:
# {
#   :base => {  # base commit results
#     "-[MPELatencyTest testLoadLatency]" => [0.2358, 0.2490, 0.2423, 0.2501, 0.2467],
#   },
#   :new => {  # new commit results
#     "-[MPELatencyTest testLoadLatency]" => [0.2245, 0.2198, 0.2312, 0.2267, 0.2289],
#   }
# }

# Restore original branch
puts "\nRestoring original branch: #{original_branch}"
system("git checkout #{original_branch} 2>&1")

# ============================================================================
# STEP 2: COMPUTE STATISTICS - Calculate all deltas and confidence intervals
# ============================================================================
test_stats = compute_statistical_report(all_results)

# ============================================================================
# STEP 3: PRINT RESULTS - Display everything
# ============================================================================
print_raw_measurements(all_results, options[:base_commit], options[:commit])
print_statistical_report(test_stats, all_results)

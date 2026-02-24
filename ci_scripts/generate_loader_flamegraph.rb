#!/usr/bin/env ruby
# Parses PaymentSheetLoader timing logs and generates a Mermaid Gantt chart
#
# Expected log format:
#   [LOADER_TIMING] START operationName 1771353097.525703
#   [LOADER_TIMING] END operationName 1771353097.926410
#
# The script calculates milliseconds elapsed from the first START timestamp.
# This is purely to help debugging load latency; feel free to delete if it's out of date / no longer useful.

require 'json'
require 'base64'
require 'uri'

class TimingEvent
  attr_accessor :name, :phase, :timestamp

  def initialize(name, phase, timestamp)
    @name = name
    @phase = phase
    @timestamp = timestamp # Unix timestamp as Float
  end

  def ms_from(start_time)
    ((timestamp - start_time) * 1000).round(3)
  end
end

class Operation
  attr_accessor :name, :start_time, :end_time

  def initialize(name)
    @name = name
    @start_time = nil
    @end_time = nil
  end

  def duration_ms
    return 0 if @start_time.nil? || @end_time.nil?
    ((@end_time - @start_time) * 1000).round(3)
  end

  def complete?
    !@start_time.nil? && !@end_time.nil?
  end

  def ms_from(start_time)
    return [0, 0] if @start_time.nil?
    start_ms = ((@start_time - start_time) * 1000).round(0).to_i
    end_ms = complete? ? ((@end_time - start_time) * 1000).round(0).to_i : start_ms
    [start_ms, end_ms]
  end
end

class TestCase
  attr_accessor :name, :events, :latency_result

  def initialize(name)
    @name = name
    @events = []
    @latency_result = nil
  end
end

# Parse input and group by test cases
test_cases = []
current_test = nil
in_test = false

ARGF.each_line do |line|
  # Test case start - match the pattern from the example
  if line =~ /Test Case '-\[StripePaymentSheetTests\.MPELatencyTest (test_\w+)\]' started\./
    test_name = $1
    current_test = TestCase.new(test_name)
    in_test = true
  # Test case end
  elsif line =~ /Test Case '-\[.*MPELatencyTest (test_\w+)\]' passed/
    if current_test
      test_cases << current_test
      current_test = nil
      in_test = false
    end
  # LOADER_TIMING event
  elsif in_test && current_test && line =~ /\[LOADER_TIMING\]\s+(\w+)\s+(\w+)\s+([\d.]+)/
    phase = $1
    name = $2
    timestamp = $3.to_f
    current_test.events << TimingEvent.new(name, phase, timestamp)
  # SYNTHETIC_LATENCY_RESULT - extract test name and latency
  elsif in_test && current_test && line =~ /SYNTHETIC_LATENCY_RESULT:\s+(test_\w+):\s+([\d.]+)/
    result_test_name = $1
    current_test.latency_result = $2.to_f
    # Update test name from the result line if we somehow didn't get it from the test case start
    current_test.name = result_test_name if current_test.name.empty?
  end
end

# Add current test if it wasn't closed properly
if current_test && !current_test.events.empty?
  test_cases << current_test
end

if test_cases.empty?
  puts "No test cases found in logs"
  exit 1
end

# Find the earliest timestamp across all test cases
earliest_timestamp = test_cases.flat_map(&:events).map(&:timestamp).min
run_date = earliest_timestamp ? Time.at(earliest_timestamp).strftime('%Y-%m-%d %H:%M:%S') : 'Unknown'

# Generate Mermaid Gantt chart
diagram_lines = []
diagram_lines << "gantt"
diagram_lines << "    title PaymentSheetLoader Order of Operations - #{run_date}"
diagram_lines << "    dateFormat x"
diagram_lines << ""

task_counter = 0

test_cases.each do |test_case|
  # Build operations from events, handling multiple instances of same operation name
  operations = []
  pending_operations = {}

  test_case.events.each do |event|
    if event.phase == 'START'
      # Create a new operation for this START
      op = Operation.new(event.name)
      op.start_time = event.timestamp
      # Track this pending operation (last one wins for matching END)
      pending_operations[event.name] = op
      operations << op
    elsif event.phase == 'END'
      # Match with the most recent pending START for this name
      if pending_operations[event.name]
        pending_operations[event.name].end_time = event.timestamp
        pending_operations.delete(event.name)
      end
    end
  end

  # Filter to only complete operations
  complete_ops = operations.select(&:complete?).sort_by(&:start_time)

  next if complete_ops.empty?

  # Find the minimum timestamp to normalize to milliseconds elapsed from 0
  min_timestamp = complete_ops.map(&:start_time).min

  # Output section for this test case
  section_name = test_case.name.gsub('_', ' ').split.map(&:capitalize).join(' ')
  latency_info = test_case.latency_result ? " (Latency: #{(test_case.latency_result * 1000).round(2)}ms)" : ""
  diagram_lines << "    section #{section_name}#{latency_info}"

  # Output all operations sorted by start time with milliseconds elapsed from start
  complete_ops.each do |op|
    # Calculate milliseconds from the start time
    start_ms, end_ms = op.ms_from(min_timestamp)
    duration_ms = op.duration_ms

    # Skip operations that took less than 1ms
    next if duration_ms < 1.0

    # Clean up name for display
    display_name = op.name.gsub(/([a-z])([A-Z])/, '\\1 \\2').gsub(/^./, &:upcase)

    # Generate unique task ID
    task_id = "t#{task_counter}"
    task_counter += 1

    diagram_lines << "    #{display_name} (#{duration_ms}ms) :#{task_id}, #{start_ms}, #{end_ms}"
  end
  diagram_lines << ""
end

# Generate link for Stripe's Mingle viewer
diagram_content = diagram_lines.join("\n")
encoded_diagram = Base64.strict_encode64(diagram_content)
diagram_url = "https://pages.stripe.me/mingle/diagrams?diagram=#{encoded_diagram}"
puts diagram_url

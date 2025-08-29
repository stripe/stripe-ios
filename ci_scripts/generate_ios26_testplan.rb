#!/usr/bin/env ruby

require 'json'
require 'find'

class IOS26TestPlanGenerator
  def initialize
    @test_plan_file = File.join(File.dirname(__dir__), 'Stripe', 'AllStripeFrameworks-iOS26.xctestplan')
    @tests_by_target = {}
  end

  def generate
    log_info "Starting iOS 26 test plan generation..."
    
    test_files = find_test_files
    
    if test_files.empty?
      log_warning "No Swift test files found"
      return
    end
    
    log_info "Found #{test_files.length} test files to scan"
    
    test_files.each { |file| process_swift_file(file) }
    
    write_test_plan
    log_results
  end

  private

  def find_test_files
    test_files = []
    
    Find.find('.') do |path|
      next unless path.end_with?('.swift')
      next unless path.include?('/Test') || path.include?('Test.swift') || path.include?('Tests.swift')
      
      test_files << path
    end
    
    test_files.sort
  end

  def process_swift_file(file_path)
    log_info "Processing: #{file_path}"
    
    content = File.read(file_path)
    class_name = extract_class_name(content)
    
    unless class_name
      log_info "  ↳ No test class found, skipping"
      return
    end
    
    # Determine target name from file path
    target_name = determine_test_target(file_path)
    unless target_name
      log_info "  ↳ Could not determine test target for #{file_path}"
      return
    end
    
    log_info "  ↳ Found test class: #{class_name} (target: #{target_name})"
    
    # Initialize target array if needed
    @tests_by_target[target_name] ||= []
    
    if class_marked_as_ios26?(content)
      log_info "  ↳ Entire class marked with @iOS26"
      add_all_test_methods(content, class_name, target_name)
    else
      individual_tests = find_individual_ios26_tests(content, class_name)
      if individual_tests.any?
        log_info "  ↳ Found #{individual_tests.length} individual @iOS26 test methods"
        @tests_by_target[target_name].concat(individual_tests)
      else
        log_info "  ↳ No @iOS26 annotations found"
      end
    end

  rescue => e
    log_warning "Could not process file #{file_path}: #{e.message}"
  end

  def extract_class_name(content)
    match = content.match(/class\s+(\w*Tests?)\s*:\s*\w*TestCase/)
    match ? match[1] : nil
  end

  def class_marked_as_ios26?(content)
    # Look for @iOS26 comment before class declaration
    content.match?(/\/\/\s*@iOS26.*?class\s+\w*Tests?\s*:/m)
  end

  def find_individual_ios26_tests(content, class_name)
    tests = []
    lines = content.lines
    
    lines.each_with_index do |line, index|
      # Check if this line has @iOS26 annotation
      if line.match?(/\/\/\s*@iOS26/)
        # Look for test method in next few lines (skip empty lines and comments)
        (index + 1...lines.length).each do |i|
          next_line = lines[i].strip
          
          # Skip empty lines and comments
          next if next_line.empty? || next_line.start_with?('//')
          
          # Check if it's a test method
          if match = next_line.match(/func\s+(test\w*)\s*\(\)/)
            test_method = match[1]
            tests << "#{class_name}/#{test_method}()"
            break
          else
            # If we hit non-test code, stop looking
            break
          end
        end
      end
    end
    
    tests
  end

  def determine_test_target(file_path)
    # Map file paths to test target names based on directory structure
    case file_path
    when /StripePaymentSheet.*Tests/
      "StripePaymentSheetTests"
    when /StripeCore.*Tests/
      "StripeCoreTests"
    when /StripePayments.*Tests/
      "StripePaymentsTests"
    when /StripePaymentsUI.*Tests/
      "StripePaymentsUITests"  
    when /StripeUICore.*Tests/
      "StripeUICoreTests"
    when /StripeConnect.*Tests/
      "StripeConnectTests"
    when /StripeIdentity.*Tests/
      "StripeIdentityTests"
    when /StripeFinancialConnections.*Tests/
      "StripeFinancialConnectionsTests"
    when /StripeCardScan.*Tests/
      "StripeCardScanTests"
    when /StripeApplePay.*Tests/
      "StripeApplePayTests"
    when /StripeCameraCore.*Tests/
      "StripeCameraCoreTests"
    when /StripeCryptoOnramp.*Tests/
      "StripeCryptoOnrampTests"
    when /Stripe3DS2.*Tests/
      if file_path.include?("DemoUI")
        "Stripe3DS2DemoUITests"
      else
        "Stripe3DS2Tests"
      end
    when /Stripe\/.*Tests/, /StripeiOS.*Tests/
      "StripeiOSTests"
    else
      nil
    end
  end

  def add_all_test_methods(content, class_name, target_name)
    test_methods = content.scan(/func\s+(test\w*)\s*\(\)/).flatten
    test_methods.each do |method|
      @tests_by_target[target_name] << "#{class_name}/#{method}()"
    end
  end

  def write_test_plan
    if File.exist?(@test_plan_file)
      # Read existing test plan
      existing_plan = JSON.parse(File.read(@test_plan_file))
      
      # Update EVERY test target with selectedTests
      existing_plan["testTargets"].each do |target|
        target_name = target["target"]["name"]
        
        if @tests_by_target[target_name] && @tests_by_target[target_name].any?
          # Sort and dedupe tests for this target
          target["selectedTests"] = @tests_by_target[target_name].sort.uniq
        else
          # Set empty array to prevent running any tests for this target
          target["selectedTests"] = []
        end
      end
      
      # Write back the modified test plan
      File.write(@test_plan_file, JSON.pretty_generate(existing_plan))
    else
      log_error "Test plan file #{@test_plan_file} does not exist. Please create it in Xcode first."
      exit 1
    end
  end

  def log_results
    if File.exist?(@test_plan_file)
      log_success "Updated #{@test_plan_file}"
      
      total_tests = @tests_by_target.values.flatten.length
      
      if total_tests > 0
        log_info "Selected tests by target (#{total_tests} total):"
        @tests_by_target.each do |target_name, tests|
          if tests.any?
            log_info "  📱 #{target_name}: #{tests.length} tests"
            tests.each { |test| puts "    • #{test}" }
          end
        end
      else
        log_warning "No @iOS26 tests found."
      end
    else
      log_error "Failed to write test plan file"
      exit 1
    end
  end

  # Logging helpers
  def log_info(message)
    puts "\e[34m[INFO]\e[0m #{message}"
  end

  def log_success(message)
    puts "\e[32m[SUCCESS]\e[0m #{message}"
  end

  def log_warning(message)
    puts "\e[33m[WARNING]\e[0m #{message}"
  end

  def log_error(message)
    puts "\e[31m[ERROR]\e[0m #{message}"
  end
end

# Run the generator
if __FILE__ == $0
  generator = IOS26TestPlanGenerator.new
  generator.generate
end


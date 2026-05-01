#!/usr/bin/env ruby

require 'json'
require 'find'

class IOS26TestPlanGeneratorV2
  def initialize
    @test_plan_file = File.join(File.dirname(__dir__), 'Stripe', 'AllStripeFrameworks-iOS26.xctestplan')
    @tests_by_target = {}
  end

  def generate
    log_info "Starting iOS 26 test plan generation..."
    
    # Find all files containing @iOS26
    annotated_files = find_annotated_files
    
    if annotated_files.empty?
      log_info "No files with @iOS26 annotations found"
      return
    end
    
    log_info "Found #{annotated_files.length} files with @iOS26 annotations"
    
    annotated_files.each { |file| process_annotated_file(file) }
    
    write_test_plan
    log_results
  end

  private

  def find_annotated_files
    files = []
    Find.find('.') do |path|
      next unless path.end_with?('.swift')
      next unless path.include?('/Test') || path.include?('Test.swift') || path.include?('Tests.swift')
      
      # Check if file contains @iOS26 annotation
      if File.read(path, encoding: 'UTF-8').include?('// @iOS26')
        files << path
      end
    rescue => e
      log_error "Could not read file #{path}: #{e.message}"
      exit 1
    end
    
    files.sort
  end

  def process_annotated_file(file_path)
    log_info "Processing: #{file_path}"
    
    content = File.read(file_path, encoding: 'UTF-8')
    lines = content.lines
    
    # Determine target name from file path
    target_name = determine_test_target(file_path)
    unless target_name
      log_error "  ↳ Could not determine test target for #{file_path}"
      exit 1
    end
    
    # Initialize target array if needed
    @tests_by_target[target_name] ||= []
    
    # Process each @iOS26 annotation
    lines.each_with_index do |line, index|
      if line.match?(/\/\/\s*@iOS26/)
        log_info "  ↳ Found @iOS26 annotation at line #{index + 1}"
        process_ios26_annotation(lines, index, target_name, file_path)
      end
    end

    rescue => e
      log_error "Could not process file #{file_path}: #{e.message}"
      exit 1
    end

  def process_ios26_annotation(lines, annotation_index, target_name, file_path)
    # Look ahead from the @iOS26 comment to find what it annotates
    (annotation_index + 1...lines.length).each do |i|
      line = lines[i].strip
      
      # Skip empty lines and comments
      next if line.empty? || line.start_with?('//')
      
      # Check if it's a class
      if class_match = line.match(/class\s+(\w*Tests?)\s*:\s*\w*TestCase/)
        class_name = class_match[1]
        log_info "    ↳ Class annotation: #{class_name}"
        add_all_test_methods_from_content(lines.join, class_name, target_name)
        break
      
      # Check if it's a test method
      elsif method_match = line.match(/func\s+(test\w*)\s*\(\)/)
        method_name = method_match[1]
        # Get the class name for this method
        class_name = find_class_name_for_method(lines, i)
        if class_name
          test_identifier = "#{class_name}/#{method_name}()"
          log_info "    ↳ Method annotation: #{test_identifier}"
          @tests_by_target[target_name] << test_identifier
        else
          log_error "    ↳ Could not find class name for method #{method_name}"
          exit 1
        end
        break
      
      # If we hit something else that's not a comment or empty line, stop looking
      else
        log_error "    ↳ @iOS26 not followed by class or test method: #{line}"
        exit 1
        break
      end
    end
  end

  def find_class_name_for_method(lines, method_index)
    # Search backwards from method to find the class declaration
    (0...method_index).reverse_each do |i|
      line = lines[i].strip
      if class_match = line.match(/class\s+(\w*Tests?)\s*:\s*\w*TestCase/)
        return class_match[1]
      end
    end
    nil
  end

  def add_all_test_methods_from_content(content, class_name, target_name)
    test_methods = content.scan(/func\s+(test\w*)\s*\(\)/).flatten
    test_methods.each do |method|
      @tests_by_target[target_name] << "#{class_name}/#{method}()"
    end
    log_info "    ↳ Added #{test_methods.length} test methods from class #{class_name}"
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
        log_info "No @iOS26 tests found."
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
  generator = IOS26TestPlanGeneratorV2.new
  generator.generate
end

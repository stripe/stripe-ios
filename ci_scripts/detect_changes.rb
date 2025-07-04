#!/usr/bin/env ruby

require 'json'
require 'set'

# Maps directories/files to the frameworks they impact
FRAMEWORK_DEPENDENCIES = {
  'StripeCore' => Set.new(['StripeCore']),
  'StripeUICore' => Set.new(['StripeUICore']),
  'Stripe3DS2' => Set.new(['Stripe3DS2']),
  'StripeApplePay' => Set.new(['StripeApplePay', 'StripePaymentSheet', 'Stripe']),
  'StripePayments' => Set.new(['StripePayments', 'StripePaymentsUI', 'StripePaymentSheet', 'Stripe']),
  'StripePaymentsUI' => Set.new(['StripePaymentsUI', 'StripePaymentSheet', 'Stripe']),
  'StripePaymentSheet' => Set.new(['StripePaymentSheet', 'Stripe']),
  'StripeIdentity' => Set.new(['StripeIdentity']),
  'StripeFinancialConnections' => Set.new(['StripeFinancialConnections', 'StripeConnect']),
  'StripeConnect' => Set.new(['StripeConnect']),
  'StripeCardScan' => Set.new(['StripeCardScan']),
  'StripeCameraCore' => Set.new(['StripeCameraCore', 'StripeIdentity']),
  'Stripe/StripeiOS' => Set.new(['Stripe'])
}.freeze

# Files that should trigger comprehensive testing
CRITICAL_FILES = Set.new([
  'Package.swift',
  'bitrise.yml',
  'Gemfile.lock',
  '.xcodeproj',
  '.xcworkspace'
]).freeze

# Files that should never trigger tests
IGNORE_FILES = Set.new([
  'README.md',
  'CHANGELOG.md',
  'CONTRIBUTING.md',
  'LICENSE',
  'NOTICE',
  'PRIVACY.md',
  'STYLEGUIDE.md',
  'MIGRATING.md',
  '.gitignore',
  '.gitattributes'
]).freeze

# Documentation and asset files
DOCS_PATTERN = /\.(md|txt|png|jpg|jpeg|gif|svg|pdf)$/i
ASSETS_PATTERN = /\.(xcassets|lproj|strings)$/i

class ChangeDetector
  def initialize(base_branch = 'origin/master')
    @base_branch = base_branch
    @changed_files = get_changed_files
    @impacted_frameworks = Set.new
    @should_run_integration = false
    @should_run_ui_tests = false
    @should_run_lint = false
    @should_skip_all_tests = false
    
    analyze_changes
  end

  def get_changed_files
    # Get changed files compared to base branch
    files = `git diff --name-only #{@base_branch}..HEAD`.split("\n")
    files += `git diff --name-only --cached`.split("\n") # Include staged changes
    files.uniq.reject(&:empty?)
  end

  def analyze_changes
    puts "🔍 Analyzing #{@changed_files.length} changed files..."
    
    # Check if we should skip all tests (only docs/assets)
    non_trivial_changes = @changed_files.reject { |file| should_ignore_file?(file) }
    
    if non_trivial_changes.empty?
      @should_skip_all_tests = true
      puts "📝 Only documentation/asset changes detected - skipping tests"
      return
    end

    @changed_files.each do |file|
      analyze_file_change(file)
    end

    # Determine what needs to run
    @should_run_lint = should_run_lint_checks?
    @should_run_integration = should_run_integration_tests?
    @should_run_ui_tests = should_run_ui_tests?

    puts "🎯 Impact analysis complete:"
    puts "  - Frameworks: #{@impacted_frameworks.to_a.sort}"
    puts "  - Integration tests: #{@should_run_integration}"
    puts "  - UI tests: #{@should_run_ui_tests}"
    puts "  - Lint: #{@should_run_lint}"
  end

  def analyze_file_change(file)
    return if should_ignore_file?(file)

    # Critical files trigger everything
    if is_critical_file?(file)
      @impacted_frameworks.merge(FRAMEWORK_DEPENDENCIES.values.flatten)
      @should_run_integration = true
      @should_run_ui_tests = true
      puts "⚠️  Critical file changed: #{file} - running all tests"
      return
    end

    # CI scripts changes
    if file.start_with?('ci_scripts/')
      @should_run_lint = true
      puts "🔧 CI script changed: #{file}"
      return
    end

    # Test files
    if file.include?('Tests/') || file.include?('Test.') || file.end_with?('Test.swift')
      framework = extract_framework_from_path(file)
      if framework
        @impacted_frameworks.add(framework)
        puts "🧪 Test file changed: #{file} -> #{framework}"
      end
      return
    end

    # Example app changes
    if file.include?('Example/')
      if file.include?('PaymentSheet Example')
        @should_run_ui_tests = true
        @impacted_frameworks.add('StripePaymentSheet')
      elsif file.include?('StripeConnect')
        @should_run_ui_tests = true
        @impacted_frameworks.add('StripeConnect')
      elsif file.include?('IntegrationTester')
        @should_run_integration = true
      end
      puts "📱 Example app changed: #{file}"
      return
    end

    # Framework source code changes
    framework = extract_framework_from_path(file)
    if framework && FRAMEWORK_DEPENDENCIES[framework]
      @impacted_frameworks.merge(FRAMEWORK_DEPENDENCIES[framework])
      puts "⚡ Framework code changed: #{file} -> #{FRAMEWORK_DEPENDENCIES[framework].to_a}"
      
      # PaymentSheet changes trigger UI tests
      if framework == 'StripePaymentSheet'
        @should_run_ui_tests = true
      end
      
      # Core changes might trigger integration tests
      if ['StripeCore', 'StripePayments'].include?(framework)
        @should_run_integration = true
      end
    end
  end

  def should_ignore_file?(file)
    # Ignore documentation files
    return true if DOCS_PATTERN.match?(File.extname(file))
    
    # Ignore specific files
    return true if IGNORE_FILES.any? { |pattern| file.include?(pattern) }
    
    # Ignore build artifacts
    return true if file.include?('build/') || file.include?('DerivedData/')
    
    false
  end

  def is_critical_file?(file)
    CRITICAL_FILES.any? { |pattern| file.include?(pattern) }
  end

  def extract_framework_from_path(file)
    # Extract framework name from file path
    parts = file.split('/')
    
    # Direct framework directory
    framework_dirs = FRAMEWORK_DEPENDENCIES.keys
    framework_dirs.each do |framework|
      return framework if file.start_with?("#{framework}/")
    end
    
    # Test directories
    if parts.any? { |part| part.end_with?('Tests') }
      test_dir = parts.find { |part| part.end_with?('Tests') }
      framework_name = test_dir.gsub(/Tests$/, '')
      return framework_name if FRAMEWORK_DEPENDENCIES.key?(framework_name)
    end
    
    nil
  end

  def should_run_lint_checks?
    # Run lint if any Swift/ObjC files changed or CI scripts changed
    @changed_files.any? do |file|
      file.end_with?('.swift', '.m', '.h') || file.start_with?('ci_scripts/')
    end
  end

  def should_run_integration_tests?
    # Run integration tests for core changes or explicit integration changes
    @should_run_integration || @changed_files.any? { |file| file.include?('IntegrationTester') }
  end

  def should_run_ui_tests?
    # Run UI tests for PaymentSheet, Connect, or example app changes
    @should_run_ui_tests || @impacted_frameworks.any? { |f| ['StripePaymentSheet', 'StripeConnect'].include?(f) }
  end

  def generate_test_matrix
    {
      skip_all_tests: @should_skip_all_tests,
      frameworks_to_test: @impacted_frameworks.to_a.sort,
      run_integration_tests: @should_run_integration,
      run_ui_tests: @should_run_ui_tests,
      run_lint: @should_run_lint,
      run_framework_tests: !@impacted_frameworks.empty?
    }
  end

  def self.run(base_branch = 'origin/master')
    detector = new(base_branch)
    matrix = detector.generate_test_matrix
    
    # Output as environment variables for Bitrise
    puts "\n🚀 Test matrix generated:"
    puts "export SKIP_ALL_TESTS=#{matrix[:skip_all_tests]}"
    puts "export FRAMEWORKS_TO_TEST='#{matrix[:frameworks_to_test].join(',')}'"
    puts "export RUN_INTEGRATION_TESTS=#{matrix[:run_integration_tests]}"
    puts "export RUN_UI_TESTS=#{matrix[:run_ui_tests]}"
    puts "export RUN_LINT=#{matrix[:run_lint]}"
    puts "export RUN_FRAMEWORK_TESTS=#{matrix[:run_framework_tests]}"
    
    # Also output as JSON for potential use in Bitrise
    File.write('test_matrix.json', JSON.pretty_generate(matrix))
    puts "\n📄 Test matrix saved to test_matrix.json"
    
    matrix
  end
end

# Run the detector if called directly
if __FILE__ == $0
  base_branch = ARGV[0] || 'origin/master'
  ChangeDetector.run(base_branch)
end
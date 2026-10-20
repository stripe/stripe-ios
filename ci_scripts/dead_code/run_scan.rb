# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'open3'
require 'rexml/document'
require 'tmpdir'
require 'yaml'

$stdout.sync = true

# Newer releases have produced duplicate declarations when indexing mixed Swift/ObjC targets.
PERIPHERY_VERSION = '3.6.0'
PERIPHERY_SHA256 = '983cb6bad09b7030f0ec151e05f650dbf450eb624bd361a0ad89c59fdbf18182'

def sdk_index_roots(config, source)
  return unless config['project'] == 'Stripe.xcworkspace' && config['schemes'] == ['AllStripeFrameworks'] && config['exclude_tests'] == true
  return unless config['build_arguments'] == ['-destination', 'generic/platform=iOS Simulator']

  scheme = REXML::Document.new(File.read(File.join(source, 'Stripe.xcworkspace/xcshareddata/xcschemes/AllStripeFrameworks.xcscheme')))
  test_action = scheme.elements['Scheme/TestAction']
  return unless test_action && test_action.attributes['buildConfiguration'] == 'Debug'
  return if test_action.elements['TestPlans']
  return unless test_action.get_elements('Testables/TestableReference').all? do |testable|
    testable.elements['BuildableReference']&.attributes&.[]('BuildableName')&.end_with?('.xctest')
  end

  entries = scheme.get_elements('Scheme/BuildAction/BuildActionEntries/BuildActionEntry')
  running = []
  testing = []
  roots = []
  entries.each do |entry|
    reference = entry.elements['BuildableReference']
    return unless reference
    name = reference.attributes['BuildableName']
    if name&.end_with?('.xctest')
      return if entry.attributes['buildForRunning'] == 'YES'
      next
    end
    return unless name&.end_with?('.framework')
    container = reference.attributes['ReferencedContainer']
    identifier = reference.attributes['BlueprintIdentifier']
    return unless container&.match?(%r{\Acontainer:Stripe[^/]*/[^/]+\.xcodeproj\z}) && identifier && !identifier.empty?

    key = [container, identifier]
    running << key if entry.attributes['buildForRunning'] == 'YES'
    if entry.attributes['buildForTesting'] == 'YES'
      testing << key
      roots << File.realpath(File.join(source, File.dirname(container.delete_prefix('container:'))))
    end
  end
  return unless !testing.empty? && running.uniq.sort == testing.uniq.sort

  roots.uniq.sort
rescue REXML::ParseException, Errno::ENOENT
  nil
end

def verify_sdk_index!(report, roots)
  indexed_roots = []
  File.foreach(report) do |line|
    match = line.match(/\A\[index:swift:phase:one\] (.+) \([^)]*\) \([\d.]+s\)\s*\z/)
    next unless match

    path = File.realpath(match[1])
    indexed_roots.concat(roots.select { |root| path.start_with?("#{root}/") })
  rescue Errno::ENOENT
    next
  end
  missing = roots - indexed_roots.uniq
  abort "Periphery did not index these SDK roots: #{missing.join(', ')}" unless missing.empty?

  puts "Verified indexed files in all #{roots.length} SDK roots."
end

abort 'Usage: run_scan.rb COMMIT OUTPUT_JSON' unless ARGV.length == 2
commit, output = ARGV
abort 'Expected an immutable commit' unless commit.match?(/\A[0-9a-f]{40}\z/)

root = File.expand_path('../..', __dir__)
output = File.expand_path(output)
FileUtils.mkdir_p(File.dirname(output))
FileUtils.rm_f(output)
tool_dir = File.join(ENV.fetch('RUNNER_TEMP'), 'dead-code-tools')
FileUtils.mkdir_p(tool_dir)
binary = File.join(tool_dir, 'periphery')

unless File.executable?(binary)
  archive = File.join(tool_dir, 'periphery.zip')
  url = "https://github.com/peripheryapp/periphery/releases/download/#{PERIPHERY_VERSION}/periphery-#{PERIPHERY_VERSION}.zip"
  system('curl', '--fail', '--location', '--retry', '3', url, '--output', archive, exception: true)
  abort 'Periphery download checksum mismatch' unless Digest::SHA256.file(archive).hexdigest == PERIPHERY_SHA256

  system('unzip', '-o', archive, '-d', tool_dir, exception: true)
end

Dir.mktmpdir('dead-code-scan-', ENV.fetch('RUNNER_TEMP')) do |temporary|
  source = root
  current, status = Open3.capture2('git', '-C', root, 'rev-parse', 'HEAD')
  abort 'Could not determine checkout commit' unless status.success?

  begin
    if current.strip != commit
      source = File.join(temporary, 'baseline')
      system('git', '-C', root, 'worktree', 'add', '--detach', source, commit, exception: true)
      # Compare both revisions using precisely the same scan configuration.
      FileUtils.cp(File.join(root, '.periphery.yml'), File.join(source, '.periphery.yml'))
    end
    reports = File.join(ENV.fetch('RUNNER_TEMP'), 'dead-code-reports')
    FileUtils.mkdir_p(reports)
    report = File.join(reports, "#{commit}.log")
    config = YAML.safe_load(File.read(File.join(source, '.periphery.yml')))
    scan_arguments = ['--clean-build']
    sdk_roots = sdk_index_roots(config, source)
    if sdk_roots
      # Periphery's build-for-testing compiles test bundles before exclude_tests
      # filters their indexes. The normal build selects the same SDK frameworks.
      # Each revision gets a fresh store so stale records cannot hide unused code.
      derived_data = File.join(temporary, 'DerivedData')
      build_log = File.join(reports, "#{commit}-build.log")
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      built = system('xcodebuild', '-workspace', 'Stripe.xcworkspace', '-scheme', 'AllStripeFrameworks',
                     '-configuration', 'Debug', '-parallelizeTargets', '-derivedDataPath', derived_data,
                     '-quiet', 'build', 'CODE_SIGNING_ALLOWED=NO', 'ENABLE_BITCODE=NO',
                     'DEBUG_INFORMATION_FORMAT=dwarf', 'COMPILER_INDEX_STORE_ENABLE=YES',
                     'INDEX_ENABLE_DATA_STORE=YES', 'ARCHS=arm64',
                     *config.fetch('build_arguments', []), chdir: source, out: build_log, err: [:child, :out])
      puts format('SDK index build: %.1fs', Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
      unless built
        warn File.readlines(build_log).last(100).join
        abort "SDK index build failed for #{commit}"
      end
      index_store = ['Index.noindex/DataStore', 'Index/DataStore'].map { |path| File.join(derived_data, path) }.find { |path| File.directory?(path) }
      abort 'SDK build did not produce an index store' unless index_store

      scan_arguments = ['--skip-build', '--index-store-path', index_store, '--verbose']
    end
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    succeeded = system(binary, 'scan', '--config', '.periphery.yml', *scan_arguments, '--retain-codable-properties', '--disable-update-check',
                       chdir: source, out: report, err: [:child, :out])
    puts format('Periphery analysis: %.1fs', Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
    unless succeeded
      warn File.readlines(report).last(100).join
      abort "Periphery scan failed for #{commit}"
    end
    verify_sdk_index!(report, sdk_roots) if sdk_roots
    system('ruby', File.join(__dir__, 'process_periphery_output.rb'), report, output, exception: true)
  ensure
    system('git', '-C', root, 'worktree', 'remove', '--force', source) if source != root
  end
end

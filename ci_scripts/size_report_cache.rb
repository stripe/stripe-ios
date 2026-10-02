# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'json'
require 'open3'
require 'yaml'
require_relative 'prepare_ci_branch'

# Each full-run worker publishes its own bundle. PRs restore all three bundles,
# regardless of which SDKs are affected or which worker originally measured them.
class SizeReportCache
  SHARDS = 3
  SCHEMA = 1
  ROOT = 'build/size-cache'
  CONTEXT = 'build/size-report-context.json'

  attr_reader :fingerprint

  def self.capture(*command)
    output, status = Open3.capture2(*command)
    raise "Failed to run #{command.join(' ')}" unless status.success?

    output
  end

  def initialize
    @modules = YAML.load_file('modules.yaml').fetch('modules')
                   .select { |mod| mod.key?('size_report') }.map { |mod| mod.fetch('framework_name') }
    # Hash the complete tracked fixture, including the patch, export options and
    # measurement code. Both revisions are built with the head revision's fixture.
    paths = self.class.capture('git', 'ls-files', '-z', 'Tests/installation_tests/size_test').split("\0")
    paths += ['ci_scripts/size_report_cache.rb', 'Gemfile.lock']
    recipe = paths.sort.map { |path| [path, Digest::SHA256.file(path).hexdigest] }
    toolchain = [self.class.capture('xcodebuild', '-version'),
                 self.class.capture('xcrun', '--sdk', 'iphoneos', '--show-sdk-build-version'),
                 self.class.capture('xcrun', 'swift', '--version')]
    @fingerprint = Digest::SHA256.hexdigest(JSON.generate([SCHEMA, SHARDS, @modules, recipe, toolchain]))
  end

  def shard(sdk)
    position = @modules.index(sdk)
    raise "Unknown size report SDK: #{sdk}" unless position

    position % SHARDS
  end

  def identity(commit, sdk)
    raise 'Size cache requires an immutable commit SHA' unless commit.match?(/\A[0-9a-f]{40}\z/)

    { 'schema' => SCHEMA, 'commit' => commit, 'sdk' => sdk, 'fingerprint' => fingerprint }
  end

  def path(commit, sdk)
    identity(commit, sdk)
    File.join(ROOT, commit, fingerprint, shard(sdk).to_s, "#{sdk}.json")
  end

  def valid_sizes?(sizes)
    sizes.is_a?(Array) && sizes.length == 2 && sizes.all? { |size| size.is_a?(Integer) && size.positive? }
  end

  def read(commit, sdk)
    entry = JSON.parse(File.read(path(commit, sdk)))
    raise TypeError, 'Expected a measurement object' unless entry.is_a?(Hash)
    expected = identity(commit, sdk)
    sizes = entry.fetch('app_size_kb')
    return sizes if expected.all? { |key, value| entry[key] == value } && valid_sizes?(sizes)

    warn "Ignoring incompatible size cache for #{sdk} at #{commit}"
    nil
  rescue Errno::ENOENT
    nil
  rescue JSON::ParserError, KeyError, TypeError => e
    warn "Ignoring invalid size cache for #{sdk}: #{e.message}"
    nil
  end

  def write(commit, sdk, sizes)
    raise "Invalid size measurement for #{sdk}: #{sizes.inspect}" unless valid_sizes?(sizes)

    destination = path(commit, sdk)
    FileUtils.mkdir_p(File.dirname(destination))
    # Store raw app totals, before subtracting the current run's empty-app size.
    File.write(destination, JSON.generate(identity(commit, sdk).merge('app_size_kb' => sizes)))
  end

  def self.prepared_comparison
    return CIBranch.prepare if ENV['SIZE_REPORT_FINGERPRINT'].to_s.empty?

    context = JSON.parse(File.read(CONTEXT), symbolize_names: true)
    raise 'Size report checkout changed after cache preparation' unless context.fetch(:head) == CIBranch.git('rev-parse', 'HEAD')

    context
  end

  def self.prepare
    comparison = CIBranch.prepare
    cache = new
    total = Integer(ENV.fetch('BITRISE_IO_PARALLEL_TOTAL', '1'))
    index = Integer(ENV.fetch('BITRISE_IO_PARALLEL_INDEX', '0'))
    unless [1, SHARDS].include?(total) && (0...total).cover?(index)
      raise "Size reports require one worker or #{SHARDS} shards"
    end
    branch = ENV['BITRISE_GIT_BRANCH'].to_s
    publish = total == SHARDS && ENV['BITRISE_PULL_REQUEST'].to_s.empty? && (branch == 'master' || branch.start_with?('releases/'))

    FileUtils.mkdir_p('build')
    File.write(CONTEXT, JSON.generate(comparison))
    {
      'SIZE_REPORT_FINGERPRINT' => cache.fingerprint,
      'SIZE_REPORT_BASE_KEY' => "size-v#{SCHEMA}-#{comparison.fetch(:base)}-#{cache.fingerprint}",
      'SIZE_REPORT_HEAD_KEY' => "size-v#{SCHEMA}-#{comparison.fetch(:head)}-#{cache.fingerprint}-#{index}",
      'SIZE_REPORT_SAVE_PATH' => File.expand_path(File.join(ROOT, comparison.fetch(:head), cache.fingerprint, index.to_s)),
      'SIZE_REPORT_PUBLISH' => publish.to_s
    }.each do |key, value|
      raise "Could not export #{key}" unless system('envman', 'add', '--key', key, '--value', value)
    end
  end
end

SizeReportCache.prepare if $PROGRAM_NAME == __FILE__

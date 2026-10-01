# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require_relative '../prepare_ci_branch'
require_relative '../size_report_modules'

class CIOptimizationTest < Minitest::Test
  SCRIPT = File.expand_path('../prepare_ci_branch.rb', __dir__)

  def setup
    @directory = Dir.mktmpdir('ci-optimization-tests-')
    @git_environment = {
      'GIT_CONFIG_GLOBAL' => '/dev/null',
      'GIT_CONFIG_NOSYSTEM' => '1',
      'GIT_AUTHOR_NAME' => 'CI Tests',
      'GIT_AUTHOR_EMAIL' => 'ci-tests@example.invalid',
      'GIT_COMMITTER_NAME' => 'CI Tests',
      'GIT_COMMITTER_EMAIL' => 'ci-tests@example.invalid'
    }
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_shallow_divergent_histories_merge_the_triggered_commit_from_a_fork
    upstream = repository('upstream')
    base = commit(upstream, 'common.txt', 'shared base')
    git(upstream, 'branch', 'unrelated')
    git(upstream, 'tag', 'unrelated-tag')
    fork = File.join(@directory, 'fork')
    git(@directory, 'clone', '--quiet', upstream, fork)
    source = import_commits(fork, 'feature', base, 125, 'source.txt')
    target = import_commits(upstream, 'master', base, 130, 'target.txt')
    checkout = shallow_clone(fork, 'feature')
    git(checkout, 'remote', 'set-url', 'origin', "file://#{upstream}")
    advanced_source = import_commits(fork, 'feature', source, 1, 'later-push.txt')
    refute_equal source, advanced_source
    assert_equal 'true', git(checkout, 'rev-parse', '--is-shallow-repository')

    comparison = in_checkout(checkout) do
      CIBranch.prepare(pr_environment(source).merge('BITRISEIO_PULL_REQUEST_REPOSITORY_URL' => "file://#{fork}"))
    end

    assert_equal({ head: source, base: base, target: target }, comparison)
    assert_equal source, git(checkout, 'rev-parse', 'HEAD')
    assert_equal %w[refs/remotes/origin/feature refs/remotes/origin/master],
                 git(checkout, 'for-each-ref', '--format=%(refname)', 'refs/remotes').lines.map(&:strip).sort
    assert_empty git(checkout, 'tag', '--list')
    in_checkout(checkout) { CIBranch.merge(comparison) }
    assert_equal [target, source], git(checkout, 'show', '-s', '--format=%P', 'HEAD').split
    assert File.exist?(File.join(checkout, 'source.txt'))
    assert File.exist?(File.join(checkout, 'target.txt'))
    refute File.exist?(File.join(checkout, 'later-push.txt')), 'A later source push must not enter the tested tree'
  end

  def test_custom_destination_branch_is_used
    upstream = repository('upstream')
    base = commit(upstream, 'common.txt', 'shared base')
    target = import_commits(upstream, 'releases/26.0', base, 2, 'release.txt')
    head = import_commits(upstream, 'feature', base, 2, 'source.txt')
    checkout = shallow_clone(upstream, 'feature')

    comparison = in_checkout(checkout) do
      CIBranch.prepare(pr_environment(head).merge('BITRISEIO_GIT_BRANCH_DEST' => 'releases/26.0'))
    end

    assert_equal({ head: head, base: base, target: target }, comparison)
    in_checkout(checkout) { CIBranch.merge(comparison) }
    assert File.exist?(File.join(checkout, 'release.txt'))
  end

  def test_merge_conflicts_fail_instead_of_testing_only_the_source
    upstream = repository('upstream')
    base = commit(upstream, 'conflict.txt', "original\n")
    target = import_commits(upstream, 'master', base, 1, 'conflict.txt')
    head = import_commits(upstream, 'feature', base, 2, 'conflict.txt')
    checkout = shallow_clone(upstream, 'feature')
    comparison = in_checkout(checkout) { CIBranch.prepare(pr_environment(head)) }

    error = assert_raises(RuntimeError) do
      in_checkout(checkout) { CIBranch.merge(comparison) }
    end

    assert_match(/failed/, error.message)
    assert_equal target, git(checkout, 'rev-parse', 'HEAD')
    assert_equal head, git(checkout, 'rev-parse', 'MERGE_HEAD')
    assert_equal 'conflict.txt', git(checkout, 'diff', '--name-only', '--diff-filter=U')
  end

  def test_unrelated_histories_fail_without_changing_the_checkout
    upstream = repository('upstream')
    commit(upstream, 'target.txt', 'unrelated target')
    git(upstream, 'checkout', '--quiet', '--orphan', 'feature')
    git(upstream, 'rm', '--quiet', '-rf', '.')
    head = commit(upstream, 'source.txt', 'unrelated source')
    checkout = shallow_clone(upstream, 'feature')

    assert_raises(RuntimeError) do
      in_checkout(checkout) { CIBranch.prepare(pr_environment(head)) }
    end

    assert_equal head, git(checkout, 'rev-parse', 'HEAD')
  end

  def test_mismatched_trigger_commit_fails_before_fetching
    upstream = repository('upstream')
    head = commit(upstream, 'source.txt', 'source')
    git(upstream, 'remote', 'add', 'origin', File.join(@directory, 'missing-remote'))

    error = assert_raises(RuntimeError) do
      in_checkout(upstream) { CIBranch.prepare(pr_environment('0' * 40)) }
    end

    assert_match(/requested commit/, error.message)
    assert_equal head, git(upstream, 'rev-parse', 'HEAD')
  end

  def test_non_pr_entrypoint_keeps_checkout_without_requiring_a_remote
    checkout = repository('checkout')
    head = commit(checkout, 'source.txt', 'source')
    output, error, status = Open3.capture3(@git_environment.merge('BITRISE_PULL_REQUEST' => ''),
                                          RbConfig.ruby, SCRIPT, chdir: checkout)

    assert status.success?, "#{output}\n#{error}"
    assert_equal head, git(checkout, 'rev-parse', 'HEAD')
  end

  def test_shared_dependency_changes_select_all_transitive_consumers
    assert_equal %w[StripeCore StripePayments StripePaymentSheet],
                 names(SizeReportModules.affected(modules, ['StripeCore/StripeCore/Networking.swift'], package))
    assert_equal %w[StripePayments StripePaymentSheet],
                 names(SizeReportModules.affected(modules, ['StripePayments/StripePayments/Payment.swift'], package))
  end

  def test_test_and_documentation_changes_do_not_measure_sdk_size
    files = ['StripePayments/StripePaymentsTests/PaymentTest.swift',
             'StripePaymentSheet/StripePaymentSheetUITests/CheckoutTest.swift',
             'Tests/ReferenceImages/snapshot.png', 'Tests/ReferenceImages_64/snapshot.png', 'Example/App/App.swift',
             'README.md', 'CHANGELOG.md', 'CONTRIBUTING.md', 'AGENTS.md', 'LICENSE']

    assert_empty SizeReportModules.affected(modules, files, package)
    assert_empty SizeReportModules.affected(modules, [], package)
  end

  def test_a_tests_named_directory_inside_shipping_sources_still_selects_the_module
    assert_equal %w[StripePayments StripePaymentSheet],
                 names(SizeReportModules.affected(modules, ['StripePayments/StripePayments/Tests/Helper.swift'], package))
  end

  def test_packaging_and_unknown_paths_select_every_module
    %w[Package.swift StripePayments.podspec ci_scripts/make_frameworks.sh BuildConfigurations/Release.xcconfig NewSDK/Source.swift].each do |file|
      assert_equal modules, SizeReportModules.affected(modules, [file], package), file
    end
  end

  def test_moving_a_source_between_modules_selects_both_sides
    checkout = repository('checkout')
    base = commit(checkout, 'StripePayments/StripePayments/Moved.swift', 'public struct Moved {}')
    destination = File.join(checkout, 'StripeConnect/StripeConnect/Moved.swift')
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.mv(File.join(checkout, 'StripePayments/StripePayments/Moved.swift'), destination)
    git(checkout, 'add', '--all')
    git(checkout, 'commit', '--quiet', '-m', 'Move source between modules')
    head = git(checkout, 'rev-parse', 'HEAD')

    selected = with_package_dump do
      in_checkout(checkout) { SizeReportModules.select(modules, { base: base, head: head }, pr_environment(head)) }
    end

    assert_equal %w[StripePayments StripePaymentSheet StripeConnect], names(selected)
  end

  def test_unknown_comparison_base_falls_back_to_measuring_every_module
    checkout = repository('checkout')
    head = commit(checkout, 'README.md', 'Documentation')

    selected = in_checkout(checkout) do
      SizeReportModules.select(modules, { base: 'missing-comparison-base', head: head }, pr_environment(head))
    end

    assert_equal modules, selected
  end

  def test_unknown_package_dependency_falls_back_to_measuring_every_module
    checkout = repository('checkout')
    base = commit(checkout, 'README.md', 'Documentation')
    head = commit(checkout, 'StripePayments/StripePayments/Payment.swift', 'public struct Payment {}')
    invalid_package = package
    invalid_package['targets'].last['dependencies'] = [{ 'product' => ['Unknown', 'ExternalPackage', nil, nil] }]

    selected = with_package_dump(invalid_package) do
      in_checkout(checkout) { SizeReportModules.select(modules, { base: base, head: head }, pr_environment(head)) }
    end

    assert_equal modules, selected
  end

  def test_non_pr_and_release_builds_measure_every_module_without_comparison_data
    [{}, { 'BITRISE_PULL_REQUEST' => '123', 'BITRISE_GIT_BRANCH' => 'releases/26.0' }].each do |environment|
      Open3.stub(:capture2, proc { flunk 'Full size reports should not need a diff or package dump' }) do
        assert_equal modules, SizeReportModules.select(modules, nil, environment)
      end
    end
  end

  def test_three_shards_measure_each_module_exactly_once
    selected = modules
    shards = (0...3).map { |index| SizeReportModules.shard(selected, shard_environment(index)) }

    assert_equal names(selected).sort, names(shards.flatten).sort
    assert_equal [2, 1, 1], shards.map(&:length)
  end

  def test_fewer_affected_modules_than_shards_leave_empty_shards
    [1, 2].each do |count|
      selected = modules.first(count)
      shards = (0...3).map { |index| SizeReportModules.shard(selected, shard_environment(index)) }

      assert_equal selected, shards.flatten
      assert_equal 3 - count, shards.count(&:empty?)
    end
  end

  def test_standalone_size_report_keeps_every_selected_module
    assert_equal modules, SizeReportModules.shard(modules, {})
  end

  def test_invalid_size_report_shards_fail_instead_of_omitting_measurements
    [{ 'BITRISE_IO_PARALLEL_TOTAL' => '0', 'BITRISE_IO_PARALLEL_INDEX' => '0' },
     shard_environment(-1), shard_environment(3)].each do |environment|
      assert_raises(RuntimeError) { SizeReportModules.shard(modules, environment) }
    end
    assert_raises(ArgumentError) { SizeReportModules.shard(modules, shard_environment('invalid')) }
    assert_raises(KeyError) { SizeReportModules.shard(modules, { 'BITRISE_IO_PARALLEL_TOTAL' => '3' }) }
  end

  private

  def repository(name)
    path = File.join(@directory, name)
    FileUtils.mkdir_p(path)
    git(path, 'init', '--quiet')
    git(path, 'checkout', '--quiet', '-b', 'master')
    path
  end

  def commit(repository, path, contents)
    full_path = File.join(repository, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, contents)
    git(repository, 'add', '--all')
    git(repository, 'commit', '--quiet', '-m', "Change #{path}")
    git(repository, 'rev-parse', 'HEAD')
  end

  def import_commits(repository, branch, base, count, path)
    input = (1..count).map do |index|
      content = "#{branch} change #{index}\n"
      message = "#{branch} commit #{index}"
      lines = ["commit refs/heads/#{branch}",
               "committer CI Tests <ci-tests@example.invalid> #{1_700_000_000 + index} +0000",
               "data #{message.bytesize}", message]
      lines << "from #{base}" if index == 1
      lines.concat(["M 100644 inline #{path}", "data #{content.bytesize}", content, ''])
      lines.join("\n")
    end.join("\n") + "\n"
    git(repository, 'fast-import', '--quiet', stdin_data: input)
    git(repository, 'rev-parse', "refs/heads/#{branch}")
  end

  def shallow_clone(repository, branch)
    path = File.join(@directory, 'checkout')
    git(@directory, 'clone', '--quiet', '--depth=1', '--single-branch', '--no-tags',
        '--branch', branch, "file://#{repository}", path)
    path
  end

  def git(repository, *arguments, stdin_data: '')
    output, error, status = Open3.capture3(@git_environment, 'git', '-C', repository, *arguments,
                                          stdin_data: stdin_data)
    raise "git #{arguments.join(' ')} failed: #{output}\n#{error}" unless status.success?

    output.strip
  end

  def in_checkout(path)
    previous = @git_environment.keys.each_with_object({}) { |key, values| values[key] = ENV[key] }
    @git_environment.each { |key, value| ENV[key] = value }
    result = nil
    capture_subprocess_io { Dir.chdir(path) { result = yield } }
    result
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def pr_environment(head)
    { 'BITRISE_PULL_REQUEST' => '123', 'BITRISE_GIT_BRANCH' => 'feature', 'BITRISE_GIT_COMMIT' => head }
  end

  def shard_environment(index)
    { 'BITRISE_IO_PARALLEL_TOTAL' => '3', 'BITRISE_IO_PARALLEL_INDEX' => index.to_s }
  end

  def modules
    %w[StripeCore StripePayments StripePaymentSheet StripeConnect].map { |name| { 'framework_name' => name } }
  end

  def package
    dependencies = { 'StripeCore' => [], 'StripePayments' => ['StripeCore'],
                     'StripePaymentSheet' => ['StripePayments'], 'StripeConnect' => [] }
    { 'targets' => dependencies.map do |name, deps|
      { 'name' => name, 'path' => "#{name}/#{name}",
        'dependencies' => deps.map { |dependency| { 'byName' => [dependency, nil] } } }
    end }
  end

  def names(modules)
    modules.map { |mod| mod.fetch('framework_name') }
  end

  def with_package_dump(contents = package)
    original = Open3.method(:capture2)
    success = Struct.new(:success?).new(true)
    replacement = proc do |*arguments|
      if arguments == ['swift', 'package', 'dump-package']
        [JSON.generate(contents), success]
      else
        original.call(*arguments)
      end
    end
    Open3.stub(:capture2, replacement) { yield }
  end
end

# frozen_string_literal: true

require 'json'
require 'open3'
require 'set'

module SizeReportModules
  def self.shard(modules, env = ENV)
    return modules if env['BITRISE_IO_PARALLEL_TOTAL'].to_s.empty?

    total = Integer(env.fetch('BITRISE_IO_PARALLEL_TOTAL'))
    index = Integer(env.fetch('BITRISE_IO_PARALLEL_INDEX'))
    raise 'Invalid size report shard' unless total.positive? && index >= 0 && index < total

    modules.each_with_index.select { |_, position| position % total == index }.map(&:first)
  end

  # Use the shipping package's dependency graph, so a shared dependency change
  # also measures every SDK that includes it. Unknown paths select all SDKs.
  def self.affected(modules, files, package)
    targets = package.fetch('targets').to_h { |target| [target.fetch('name'), target] }
    dependencies = targets.transform_values do |target|
      target.fetch('dependencies', []).map do |dependency|
        reference = dependency['byName'] || dependency['target']
        raise 'Unrecognized package dependency' unless reference && targets.key?(reference.first)

        reference.first
      end
    end
    roots = targets.keys.to_h do |name|
      path = targets.fetch(name).fetch('path')
      [path.split('/').first, name]
    end
    changed = Set.new
    files.each do |path|
      # Documentation and example/test-only edits do not change shipped size.
      next if path.start_with?('Example/', 'Tests/ReferenceImages/', 'Tests/ReferenceImages_64/')
      next if %w[README.md CHANGELOG.md CONTRIBUTING.md AGENTS.md LICENSE].include?(path)

      name = roots[path.split('/').first]
      return modules unless name

      target_path = targets.fetch(name).fetch('path') + '/'
      next if !path.start_with?(target_path) && path.split('/').any? { |part| part.end_with?('Tests') }

      changed << name
    end
    loop do
      previous = changed.size
      dependencies.each { |name, deps| changed << name if deps.any? { |dep| changed.include?(dep) } }
      break if changed.size == previous
    end
    modules.select do |mod|
      name = mod.fetch('framework_name')
      raise "Missing package target #{name}" unless targets.key?(name)

      changed.include?(name)
    end
  end

  def self.select(modules, comparison, env = ENV)
    return modules if env['BITRISE_PULL_REQUEST'].to_s.empty? || env['BITRISE_GIT_BRANCH'].to_s.start_with?('releases/')

    # Disable rename detection so moves select both the old and new module.
    files, status = Open3.capture2('git', 'diff', '--name-only', '--no-renames', '-z',
                                 comparison.fetch(:base), comparison.fetch(:head))
    raise 'Could not read changed files' unless status.success?

    package, status = Open3.capture2('swift', 'package', 'dump-package')
    raise 'Could not read package dependencies' unless status.success?

    affected(modules, files.split("\0"), JSON.parse(package))
  rescue StandardError => e
    warn "Measuring every SDK because size selection failed: #{e.message}"
    modules
  end
end

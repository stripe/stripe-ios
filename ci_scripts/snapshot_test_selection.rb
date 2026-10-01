# frozen_string_literal: true

require 'json'
require 'open3'
require 'rexml/document'
require 'set'

module SnapshotTestSelection
  def self.discover(root)
    Dir.glob(File.join(root, '**/*Snapshot{Test,Tests}.{swift,m}')).map do |file|
      relative = file.delete_prefix(root + '/')
      target = relative.split('/').find { |part| part.end_with?('Tests') }
      target = 'StripeiOS Tests' if target == 'Tests'
      "#{target}/#{File.basename(file, '.*')}" if target
    end.compact.sort.uniq
  end

  # Xcode test targets link additional SDKs and shared test utilities that are
  # absent from the shipping Package.swift graph. Include these dependencies.
  def self.graph(root)
    targets = {}
    products = {}
    Dir.glob(File.join(root, 'Stripe*/*.xcodeproj/project.pbxproj')).each do |file|
      json, status = Open3.capture2('plutil', '-convert', 'json', '-o', '-', file)
      raise "Could not read #{file}" unless status.success?

      objects = JSON.parse(json).fetch('objects')
      objects.each do |id, object|
        next unless object['isa'] == 'PBXNativeTarget'

        target = object.merge('objects' => objects, 'root' => file.delete_prefix(root + '/').split('/').first)
        raise "Duplicate target ID #{id}" if targets.key?(id)

        targets[id] = target
        product = objects.fetch(object.fetch('productReference')).fetch('path')
        raise "Duplicate product #{product}" if products.key?(product)

        products[product] = id
      end
    end
    targets.each_value do |target|
      objects = target.fetch('objects')
      dependencies = target.fetch('dependencies').map do |id|
        dependency = objects.fetch(id)
        dependency['target'] || objects.fetch(dependency.fetch('targetProxy')).fetch('remoteGlobalIDString')
      end
      target.fetch('buildPhases').each do |phase_id|
        phase = objects.fetch(phase_id)
        next unless %w[PBXFrameworksBuildPhase PBXCopyFilesBuildPhase].include?(phase['isa'])

        phase.fetch('files').each do |id|
          reference = objects.fetch(id)['fileRef']
          next unless reference

          product = objects.fetch(reference)
          next unless product['sourceTree'] == 'BUILT_PRODUCTS_DIR'

          dependencies << products.fetch(product.fetch('path'))
        end
      end
      raise "Unknown dependencies for #{target['name']}" unless dependencies.all? { |id| targets.key?(id) }

      target['linkedTargets'] = dependencies.uniq
    end
    targets
  end

  def self.affected(tests, files, targets)
    known_names = targets.values.map { |target| target.fetch('name') }
    return tests unless tests.all? { |test| known_names.include?(test.split('/').first) }

    changed_roots = files.map { |file| file.split('/').first }.uniq
    return tests unless (changed_roots - targets.values.map { |target| target.fetch('root') }).empty?

    changed = targets.select { |_, target| changed_roots.include?(target.fetch('root')) }.keys.to_set
    loop do
      previous = changed.size
      targets.each do |id, target|
        changed << id if target.fetch('linkedTargets').any? { |dependency| changed.include?(dependency) }
      end
      break if changed.size == previous
    end
    names = changed.map { |id| targets.fetch(id).fetch('name') }.to_set
    tests.select { |test| names.include?(test.split('/').first) }
  end

  def self.select(tests, root, env = ENV)
    return tests if env['BITRISE_PULL_REQUEST'].to_s.empty? || env['BITRISE_GIT_BRANCH'].to_s.start_with?('releases/')

    destination = env['BITRISEIO_GIT_BRANCH_DEST'].to_s
    destination = 'master' if destination.empty?
    files, status = Open3.capture2('git', 'diff', '--no-renames', '--name-only', '-z', "origin/#{destination}...HEAD", chdir: root)
    raise 'Could not determine changed files' unless status.success?

    affected(tests, files.split("\0"), graph(root))
  rescue StandardError => e
    warn "Recording every snapshot because selection failed: #{e.message}"
    tests
  end

  # A dedicated scheme prevents -only-testing from still building the explicit
  # framework entries in AllStripeFrameworks. Xcode builds each test's actual
  # dependencies through the workspace's existing implicit dependency graph.
  def self.with_scheme(root, tests, plan: nil)
    return if tests.empty?

    names = tests.map { |test| test.split('/').first }.uniq
    source = REXML::Document.new(File.read(File.join(root, 'Stripe.xcworkspace/xcshareddata/xcschemes/AllStripeFrameworks.xcscheme')))
    references = source.get_elements('Scheme/TestAction/Testables/TestableReference').select do |testable|
      names.include?(testable.elements['BuildableReference'].attributes['BlueprintName'])
    end
    found = references.map { |testable| testable.elements['BuildableReference'].attributes['BlueprintName'] }
    raise "Missing snapshot targets: #{names - found}" unless (names - found).empty?

    document = REXML::Document.new
    scheme = document.add_element('Scheme', 'version' => '1.7')
    build = scheme.add_element('BuildAction', 'parallelizeBuildables' => 'YES', 'buildImplicitDependencies' => 'YES')
    entries = build.add_element('BuildActionEntries')
    references.each do |testable|
      entry = entries.add_element('BuildActionEntry', 'buildForTesting' => 'YES', 'buildForRunning' => 'NO',
                                 'buildForProfiling' => 'NO', 'buildForArchiving' => 'NO', 'buildForAnalyzing' => 'NO')
      entry.add_element(testable.elements['BuildableReference'].deep_clone)
    end
    action = scheme.add_element('TestAction', 'buildConfiguration' => 'Debug', 'shouldUseLaunchSchemeArgsEnv' => 'NO')
    action.add_element('MacroExpansion').add_element(references.first.elements['BuildableReference'].deep_clone)
    environment = source.elements['Scheme/TestAction/EnvironmentVariables']
    action.add_element(environment.deep_clone) if environment
    name = "SnapshotTests-CI-#{Process.pid}"
    scheme_file = File.join(root, "Stripe.xcworkspace/xcshareddata/xcschemes/#{name}.xcscheme")
    if plan
      plan = Marshal.load(Marshal.dump(plan))
      plan.fetch('testTargets').select! { |target| names.include?(target.fetch('target').fetch('name')) }
      plan.fetch('testTargets').each do |target|
        target.fetch('selectedTests').select! do |test|
          tests.include?("#{target.fetch('target').fetch('name')}/#{test.split('/').first}")
        end
      end
      plan.fetch('defaultOptions')['targetForVariableExpansion'] = plan.fetch('testTargets').first.fetch('target').dup
      plan_file = File.join(root, "Stripe/#{name}.xctestplan")
      File.write(plan_file, JSON.pretty_generate(plan))
      action.add_element('TestPlans').add_element('TestPlanReference', 'reference' => "container:Stripe/#{name}.xctestplan", 'default' => 'YES')
    else
      testables = action.add_element('Testables')
      references.each { |reference| testables.add_element(reference.deep_clone) }
    end
    File.write(scheme_file, document.to_s)
    yield name
  ensure
    File.delete(scheme_file) if scheme_file && File.exist?(scheme_file)
    File.delete(plan_file) if plan_file && File.exist?(plan_file)
  end
end

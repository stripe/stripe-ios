#!/usr/bin/ruby
# Every UI test must run in exactly one shard, including methods of split classes.

require 'json'
require 'set'

module PaymentSheetTestSharding
  ROOT = File.expand_path('..', __dir__)
  EXAMPLE = File.join(ROOT, 'Example/PaymentSheet Example')
  DECLARATION_PREFIX = /[ \t]*(?:(?:@\w+(?:\([^\n]*?\))?|public|open|internal|fileprivate|private|final|override|nonisolated)\s+)*/

  def self.test_classes(directory)
    classes = {}
    Dir.glob(File.join(directory, '**/*.swift')).sort.each do |path|
      # Commented-out tests are not part of the XCTest suite.
      source = File.read(path).gsub(%r{/\*.*?\*/}m, '').gsub(%r{^\s*//[^\n]*}, '')
      declarations = source.scan(/^#{DECLARATION_PREFIX}class\s+(\w+)\s*:\s*(\w+)/)
      methods = source.scan(/^#{DECLARATION_PREFIX}func\s+(test\w+)\s*\(\s*\)/).flatten
      candidates = source.scan(/\bfunc\s+(test\w+)\s*\(\s*\)/).flatten
      unless candidates.sort == methods.sort
        raise "Unrecognized test declaration in #{path}; update the sharding inventory parser"
      end
      next if declarations.empty? && methods.empty?

      # The UI suite keeps one test class per source file. Fail visibly if that
      # changes, rather than assigning methods to the wrong class.
      raise "Expected one test class in #{path}" unless declarations.length == 1

      name, parent = declarations.first
      classes[name] = { parent: parent, methods: methods }
    end

    inherited_methods = lambda do |name|
      return [] if name == 'XCTestCase'

      definition = classes.fetch(name) { raise "Unknown test superclass #{name}" }
      (definition[:methods] + inherited_methods.call(definition[:parent])).uniq
    end

    classes.to_h { |name, _| [name, inherited_methods.call(name)] }
  end

  def self.inventory(example = EXAMPLE)
    %w[PaymentSheetUITest PaymentSheetLocalizationScreenshotGenerator].to_h do |target|
      classes = test_classes(File.join(example, target))
      raise "No test methods found for #{target}" if classes.values.flatten.empty?

      [target, classes]
    end
  end

  def self.expand(selectors, classes)
    selectors.flat_map do |selector|
      name, method = selector.split('/', 2)
      methods = classes.fetch(name) { raise "Unknown test class #{name}" }
      if method
        method = method.delete_suffix('()')
        raise "Unknown test #{selector}" unless methods.include?(method)

        ["#{name}/#{method}"]
      else
        methods.map { |test| "#{name}/#{test}" }
      end
    end.to_set
  end

  def self.check(plans, inventory)
    counts = Hash.new(0)
    expected = inventory.flat_map do |target, classes|
      classes.flat_map { |name, methods| methods.map { |method| "#{target}/#{name}/#{method}" } }
    end

    plans.each do |plan|
      plan.fetch('testTargets').each do |target|
        next if target['enabled'] == false

        name = target.fetch('target').fetch('name')
        classes = inventory.fetch(name) { raise "Unknown test target #{name}" }
        selected = expand(target.fetch('selectedTests', classes.keys), classes)
        skipped = expand(target.fetch('skippedTests', []), classes)
        (selected - skipped).each { |test| counts["#{name}/#{test}"] += 1 }
      end
    end

    expected.map do |test|
      "#{test} runs in #{counts[test]} shards; expected exactly one." unless counts[test] == 1
    end.compact
  end

  def self.main
    paths = Dir.glob(File.join(EXAMPLE, 'PaymentSheet Example-Shard*.xctestplan')).sort
    raise 'No PaymentSheet shard plans found' if paths.empty?

    plans = paths.map { |path| JSON.parse(File.read(path)) }
    errors = check(plans, inventory)
    unless errors.empty?
      warn errors.join("\n")
      abort 'Update the PaymentSheet Example-Shard test plans so every UI test is selected exactly once.'
    end
    puts "Every PaymentSheet UI test is selected exactly once across #{plans.length} shards."
  end
end

PaymentSheetTestSharding.main if $PROGRAM_NAME == __FILE__

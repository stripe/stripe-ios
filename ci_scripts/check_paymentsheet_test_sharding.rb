#!/usr/bin/ruby
# Shards 1–3 select individual tests; shard 4 runs everything else, including new tests.
# After rebalancing shards 1–3, run this script with --update to regenerate shard 4.

require 'json'

module PaymentSheetTestSharding
  EXAMPLE = File.expand_path('../Example/PaymentSheet Example', __dir__)
  UI_TARGET = 'PaymentSheetUITest'
  LOCALIZATION_TARGET = 'PaymentSheetLocalizationScreenshotGenerator'

  def self.settings(plan)
    plan.reject { |key, _| key == 'testTargets' }.merge(
      'configurations' => plan.fetch('configurations').map { |config| config.reject { |key, _| %w[id name].include?(key) } }
    )
  end

  def self.exclusions(plans)
    raise 'Expected four PaymentSheet shard plans' unless plans.length == 4

    targets = plans.each_with_index.map do |plan, index|
      raise 'Shard settings must match' unless settings(plan) == settings(plans.first)

      entries = plan.fetch('testTargets')
      expected = index.zero? ? [UI_TARGET, LOCALIZATION_TARGET] : [UI_TARGET]
      raise "Unexpected targets in shard #{index + 1}" unless entries.map { |entry| entry.fetch('target').fetch('name') }.sort == expected.sort

      raise 'Shard targets must be enabled' if entries.any? { |entry| entry['enabled'] == false }

      if index.zero?
        localization = entries.find { |entry| entry.fetch('target').fetch('name') == LOCALIZATION_TARGET }
        raise 'Shard 1 must run all localization tests' if localization.key?('selectedTests') || localization.key?('skippedTests')
      end
      entries.find { |entry| entry.fetch('target').fetch('name') == UI_TARGET }
    end
    options = targets.map { |target| target.reject { |key, _| %w[selectedTests skippedTests].include?(key) } }
    raise 'UI target and options must match across shards' unless options.uniq.length == 1
    raise 'Shard 4 must run all tests except the generated exclusions' if targets.last.key?('selectedTests')

    selected = targets.first(3).flat_map do |target|
      raise 'Shards 1–3 cannot skip tests' if target.key?('skippedTests')

      tests = target.fetch('selectedTests')
      unless tests.is_a?(Array) && !tests.empty? && tests.all? do |test|
        test.is_a?(String) && test.split('/').length == 2 && test.end_with?('()') && !test.include?('*')
      end
        raise 'Shards 1–3 must select individual Class/testMethod() entries'
      end
      tests
    end
    duplicates = selected.group_by { |test| test }.select { |_, occurrences| occurrences.length > 1 }.keys
    raise "Tests assigned more than once: #{duplicates.join(', ')}" unless duplicates.empty?

    selected.sort
  end

  def self.main(arguments = ARGV, example = EXAMPLE)
    raise 'Usage: check_paymentsheet_test_sharding.rb [--update]' unless arguments.empty? || arguments == ['--update']

    paths = (1..4).map { |index| File.join(example, "PaymentSheet Example-Shard#{index}.xctestplan") }
    unless Dir.glob(File.join(example, 'PaymentSheet Example-Shard*.xctestplan')).sort == paths
      raise 'Expected exactly PaymentSheet Example-Shard1 through Shard4.xctestplan'
    end
    plans = paths.map { |path| JSON.parse(File.read(path)) }
    skipped = exclusions(plans)
    catch_all = plans.last.fetch('testTargets').first
    if arguments == ['--update']
      catch_all['skippedTests'] = skipped
      File.write(paths.last, JSON.pretty_generate(plans.last, space_before: ' ') + "\n")
    elsif catch_all['skippedTests'] != skipped
      raise 'Shard 4 exclusions are out of date. Run ci_scripts/check_paymentsheet_test_sharding.rb --update'
    end
    puts 'Shards 1–3 have unique assignments; shard 4 selects all remaining UI tests.'
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    PaymentSheetTestSharding.main
  rescue StandardError => e
    abort e.message
  end
end

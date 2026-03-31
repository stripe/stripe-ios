#!/usr/bin/env ruby

module ChangelogUtils
  CHANGELOG_PATH = 'CHANGELOG.md'.freeze
  BUMP_INTRO_LINE = "The next release's version bump will so far be:".freeze
  PLACEHOLDER_HEADING = '## X.Y.Z - changes pending release'.freeze
  VALID_BUMP_MARKERS = %w[MAJOR MINOR PATCH].freeze
  VERSION_HEADING_PATTERN = /^## \d+\.\d+\.\d+ \d{4}-\d{2}-\d{2}$/.freeze
  PLACEHOLDER_HEADING_PATTERN = /^## (X.Y.Z|X.X.X)( - changes pending release)?\s*$/i.freeze

  module_function

  def changelog_lines(filename = CHANGELOG_PATH)
    File.readlines(filename)
  end

  def changelog_metadata(filename = CHANGELOG_PATH)
    lines = changelog_lines(filename)
    {
      intro: lines[0],
      bump: lines[1],
      spacer: lines[2],
      placeholder: lines[3]
    }
  end

  def validate_metadata!(filename = CHANGELOG_PATH)
    metadata = changelog_metadata(filename)

    raise "CHANGELOG.md line 1 must be exactly:\n#{BUMP_INTRO_LINE}" unless metadata[:intro]&.chomp == BUMP_INTRO_LINE
    raise 'CHANGELOG.md line 2 must be one of: MAJOR, MINOR, PATCH' unless valid_bump_marker?(metadata[:bump]&.chomp)
    raise 'CHANGELOG.md line 3 must be blank.' unless metadata[:spacer] == "\n"
    raise "CHANGELOG.md line 4 must be the unreleased placeholder heading:\n#{PLACEHOLDER_HEADING}" unless metadata[:placeholder]&.chomp&.match?(PLACEHOLDER_HEADING_PATTERN)
  end

  def valid_bump_marker?(marker)
    VALID_BUMP_MARKERS.include?(marker)
  end

  def bump_marker(filename = CHANGELOG_PATH)
    validate_metadata!(filename)
    changelog_metadata(filename)[:bump].chomp
  end

  def validate_bump_for_api_change!(severity, filename = CHANGELOG_PATH)
    normalized_severity = severity.to_s.strip
    return if normalized_severity.empty? || normalized_severity == 'none'

    marker = bump_marker(filename)
    allowed_markers = required_bump_markers_for_api_change(normalized_severity)
    return if allowed_markers.include?(marker)

    allowed_description = allowed_markers.join(' or ')
    raise "CHANGELOG.md line 2 must be #{allowed_description} when verify public interface detects a #{normalized_severity} API change. Found #{marker}."
  end

  def required_bump_markers_for_api_change(severity)
    case severity
    when 'public'
      ['MAJOR']
    when 'spi'
      %w[MAJOR MINOR]
    when 'none', ''
      VALID_BUMP_MARKERS
    else
      raise "Unknown API change severity: #{severity.inspect}"
    end
  end

  def infer_bump_marker(previous_version, next_version)
    previous_parts = parse_version(previous_version)
    next_parts = parse_version(next_version)

    # Compare semantic version parts left-to-right and require the next version to be strictly newer.
    comparison = next_parts <=> previous_parts
    raise "Expected #{next_version} to be newer than #{previous_version}." unless comparison == 1

    return 'MAJOR' if next_parts[0] > previous_parts[0]
    return 'MINOR' if next_parts[1] > previous_parts[1]

    'PATCH'
  end

  def release_notes_for_version(version, filename = CHANGELOG_PATH)
    changelog = +''
    reading = false

    File.foreach(filename) do |line|
      break if reading && line.start_with?('## ')

      if line.start_with?("## #{version} ")
        reading = true
      end

      changelog << line if reading
    end

    changelog
  end

  def update_changelog_for_release!(version, filename = CHANGELOG_PATH, date = Time.now.strftime('%Y-%m-%d'))
    lines = changelog_lines(filename)
    validate_metadata!(filename)

    placeholder_index = lines.index { |line| line.chomp.match?(PLACEHOLDER_HEADING_PATTERN) }
    raise "Unable to find unreleased placeholder heading in #{filename}." if placeholder_index.nil?

    updated_lines = []
    lines.each_with_index do |line, index|
      if index == 1
        updated_lines << "PATCH\n"
      elsif index == placeholder_index
        updated_lines << "#{PLACEHOLDER_HEADING}\n"
        updated_lines << "\n"
        updated_lines << "## #{version} #{date}\n"
      elsif index == placeholder_index + 1 && line == "\n"
        next
      else
        updated_lines << line
      end
    end

    File.write(filename, updated_lines.join)
  end

  def parse_version(version)
    version.split('.').map(&:to_i)
  end
end

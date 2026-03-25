#!/usr/bin/env ruby

# frozen_string_literal: true

require_relative 'changelog_utils'

begin
  ChangelogUtils.validate_metadata!
rescue StandardError => e
  abort("ERR: #{e.message}")
end

current_version = File.open('VERSION', &:readline).strip
expected_latest_release_heading = Regexp.new("^## #{Regexp.escape(current_version)} \\d{4}-\\d{2}-\\d{2}$")
first_version_heading = File.readlines('CHANGELOG.md').find { |line| line.match?(ChangelogUtils::VERSION_HEADING_PATTERN) }

unless first_version_heading&.match?(expected_latest_release_heading)
  abort(
    <<~MESSAGE
      ERR: The first released version entry in CHANGELOG.md must match VERSION:

      ## #{current_version} [ISO 8601 DATE]
    MESSAGE
  )
end

File.readlines('CHANGELOG.md').each_with_index do |line, index|
  line_number = index + 1
  next unless line.start_with?('## ')

  next if line.match?(ChangelogUtils::VERSION_HEADING_PATTERN) || line.match?(ChangelogUtils::PLACEHOLDER_HEADING_PATTERN)

  abort(
    <<~MESSAGE
      ERR: Line #{line_number} uses ## header but is not a version/date format:

      #{line.strip}

      ## headers should only be used for version entries like:
      ## 1.2.3 2024-01-15
      ## X.Y.Z - changes pending release

      Use ### for module names instead.
    MESSAGE
  )
end

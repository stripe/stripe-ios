#!/usr/bin/env ruby

# frozen_string_literal: true

current_version = File.open('VERSION', &:readline).strip

LATEST_RELEASE_HEADING_PATTERN = Regexp.new(
  "^## #{current_version} \\d{4}-\\d{2}-\\d{2}"
)

PLACEHOLDER_HEADING_PATTERN = /^## (X.Y.Z|X.X.X)/i.freeze
VERSION_HEADING_PATTERN = /^## \d+\.\d+\.\d+ \d{4}-\d{2}-\d{2}$/

first_line = File.open('CHANGELOG.md', &:readline)
unless first_line.match(LATEST_RELEASE_HEADING_PATTERN) ||
       first_line.match(PLACEHOLDER_HEADING_PATTERN)
  abort(
    <<~MESSAGE
      ERR: First line of CHANGELOG.md must be in the following format:

      ## [CURRENT VERSION] [ISO 8601 DATE]

      For unreleased versions use the following placeholder:

      ## X.Y.Z
    MESSAGE
  )
end

# Check that all ## headers follow version/date format or placeholder format
File.readlines('CHANGELOG.md').each_with_index do |line, index|
  line_number = index + 1
  next unless line.start_with?('## ')
  
  unless line.match(VERSION_HEADING_PATTERN) || line.match(PLACEHOLDER_HEADING_PATTERN)
    abort(
      <<~MESSAGE
        ERR: Line #{line_number} uses ## header but is not a version/date format:
        
        #{line.strip}
        
        ## headers should only be used for version entries like:
        ## 1.2.3 2024-01-15
        ## X.Y.Z (for unreleased)
        
        Use ### for module names instead.
      MESSAGE
    )
  end
end

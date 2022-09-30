#!/usr/bin/env ruby

# frozen_string_literal: true

current_version = File.open('VERSION', &:readline).strip

LATEST_RELEASE_HEADING_PATTERN = Regexp.new(
  "^## #{current_version} \\d{4}-\\d{2}-\\d{2}"
)

PLACEHOLDER_HEADING_PATTERN = /^## (X.Y.Z|X.X.X)/i.freeze

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

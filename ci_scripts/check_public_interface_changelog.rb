#!/usr/bin/env ruby

require_relative 'changelog_utils'

severity = ARGV[0].to_s.strip

begin
  ChangelogUtils.validate_bump_for_api_change!(severity)
rescue StandardError => e
  abort(e.message)
end

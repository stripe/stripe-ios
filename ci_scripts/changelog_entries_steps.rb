#!/usr/bin/env ruby
# frozen_string_literal: true

# changelog_entries_steps.rb
#
# Generates changelog entries for all commits since the last release by calling
# changelog_status_for_commit.rb for each one. Integrates into the release flow.
#
# Usage:
#   ruby ci_scripts/changelog_entries_steps.rb
#   ruby ci_scripts/changelog_entries_steps.rb --dry-run

require 'json'
require 'open3'
require 'set'

require_relative 'changelog_utils'

# rputs is defined in common.rb (requires colorize gem). Fall back gracefully
# so this script can run standalone without the full release gem bundle.
unless defined?(rputs)
  def rputs(string)
    puts string
  end
end

# Matches PR numbers in various formats found in CHANGELOG entries:
#   [Tag][6611](url)  — our generated format
#   (#6611)           — common in manual entries and commit messages
#   #6611             — bare reference
CHANGELOG_PR_PATTERNS = [
  /\[[\w]+\]\[(\d+)\]/,
  /\(#(\d+)\)/,
  /(?:^|\s)#(\d+)(?:\s|$)/,
].freeze

def generate_changelog_entries(dry_run: false)
  last_release_version = most_recent_released_version
  release_tag = last_release_version

  commits = commits_since_release(release_tag)
  if commits.empty?
    rputs "No commits since #{release_tag}; skipping changelog generation."
    return
  end

  existing_pr_numbers = changelog_pr_numbers_in_unreleased
  commits = commits.reject { |c| existing_pr_numbers.include?(c[:pr_number].to_i) }

  if commits.empty?
    rputs "All commits since #{release_tag} already have changelog entries."
    return
  end

  puts "Processing #{commits.length} commit(s) since #{release_tag}..."

  responses = commits.filter_map do |commit|
    result = run_changelog_status(commit)
    next unless result && result['include_changelog_entry']

    result.merge('pr_number' => commit[:pr_number])
  end

  if responses.empty?
    rputs "No new changelog entries needed."
    return
  end

  # Validate bump consistency
  current_bump = ChangelogUtils.bump_marker
  validate_bump_consistency!(current_bump, responses)

  if dry_run
    puts "\n#{'=' * 60}"
    puts "DRY RUN — would add #{responses.length} entries:"
    puts '=' * 60
    responses.each do |r|
      puts "  ### #{r['section']}"
      puts "  #{r['message']}"
      puts "  bump: #{r['bump_type']}"
      puts
    end
    return
  end

  apply_entries_to_changelog(responses)
  update_bump_marker(responses)

  puts "Added #{responses.length} changelog #{responses.length == 1 ? 'entry' : 'entries'}."
end

private

def most_recent_released_version
  lines = File.readlines('CHANGELOG.md')
  lines.each do |line|
    match = line.match(ChangelogUtils::VERSION_HEADING_PATTERN)
    return line.match(/## (\d+\.\d+\.\d+)/)[1] if match
  end
  raise 'Could not find a released version in CHANGELOG.md'
end

def commits_since_release(version)
  tag_candidates = ["#{version}", "v#{version}"]
  tag = tag_candidates.find { |t| system("git rev-parse --verify #{t} > /dev/null 2>&1") }
  raise "No git tag found for version #{version} (tried #{tag_candidates.join(', ')})" unless tag

  stdout, _, status = Open3.capture3('git', 'log', "#{tag}..HEAD", '--format=%H %s')
  raise "git log failed" unless status.success?

  seen_prs = Set.new
  stdout.split("\n").filter_map do |line|
    sha = line.split(' ').first
    pr_match = line.match(/\(#(\d+)\)/)
    next unless pr_match

    pr_number = pr_match[1]
    next if seen_prs.include?(pr_number)

    seen_prs.add(pr_number)
    { hash: sha, pr_number: pr_number }
  end
end

def run_changelog_status(commit)
  input = JSON.generate({
    pr_number: commit[:pr_number],
    hash: commit[:hash],
  })

  script = File.expand_path('changelog_status_for_commit.rb', __dir__)
  stdout, stderr, status = Open3.capture3('ruby', script, input)

  unless status.success?
    warn "  ⚠️  changelog_status_for_commit failed for #{commit[:hash][0, 7]} (PR ##{commit[:pr_number]}): #{stderr.strip}"
    return nil
  end

  JSON.parse(stdout)
rescue JSON::ParserError => e
  warn "  ⚠️  Invalid JSON from changelog_status_for_commit for #{commit[:hash][0, 7]}: #{e.message}"
  nil
end

def changelog_pr_numbers_in_unreleased
  content = File.read('CHANGELOG.md')
  # Find everything between the placeholder heading and the first real version
  placeholder_idx = content.index(ChangelogUtils::PLACEHOLDER_HEADING)
  return Set.new unless placeholder_idx

  version_match = content.match(ChangelogUtils::VERSION_HEADING_PATTERN)
  return Set.new unless version_match

  unreleased_section = content[placeholder_idx...version_match.begin(0)]
  pr_numbers = Set.new
  CHANGELOG_PR_PATTERNS.each do |pattern|
    unreleased_section.scan(pattern).flatten.each { |n| pr_numbers.add(n.to_i) }
  end
  pr_numbers
end

def validate_bump_consistency!(current_bump, responses)
  bump_priority = { 'patch' => 0, 'minor' => 1, 'major' => 2 }
  max_response_bump = responses.map { |r| r['bump_type'] }.max_by { |b| bump_priority[b] || 0 }

  current_priority = bump_priority[current_bump.downcase] || 0
  max_priority = bump_priority[max_response_bump] || 0

  if max_priority > current_priority
    warn "⚠️  CHANGELOG bump marker is #{current_bump} but commits require #{max_response_bump.upcase}. Updating."
  end
end

def apply_entries_to_changelog(entries)
  content = File.read('CHANGELOG.md')
  lines = content.split("\n")

  # Find insertion point (after the placeholder heading)
  insertion_idx = lines.index { |l| l.match?(ChangelogUtils::PLACEHOLDER_HEADING_PATTERN) }
  raise 'Could not find placeholder heading in CHANGELOG.md' unless insertion_idx

  # Group entries by section
  grouped = entries.group_by { |e| e['section'] }

  new_lines = []
  grouped.each do |section, section_entries|
    new_lines << ""
    new_lines << "### #{section}"
    section_entries.each do |entry|
      new_lines << entry['message']
    end
  end

  lines.insert(insertion_idx + 1, *new_lines)
  File.write('CHANGELOG.md', lines.join("\n"))
end

def update_bump_marker(responses)
  bump_priority = { 'patch' => 0, 'minor' => 1, 'major' => 2 }
  max_bump = responses.map { |r| r['bump_type'] }.max_by { |b| bump_priority[b] || 0 }

  lines = File.readlines('CHANGELOG.md')
  current_bump = lines[1].strip
  if bump_priority.fetch(max_bump, 0) > bump_priority.fetch(current_bump.downcase, 0)
    lines[1] = "#{max_bump.upcase}\n"
    File.write('CHANGELOG.md', lines.join)
    puts "⬆️  Bump marker updated: #{current_bump} → #{max_bump.upcase}"
  end
end

# --- Entry point ---

if __FILE__ == $PROGRAM_NAME
  dry_run = ARGV.include?('--dry-run')
  generate_changelog_entries(dry_run: dry_run)
end

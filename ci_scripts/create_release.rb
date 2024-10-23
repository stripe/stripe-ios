#!/usr/bin/env ruby

require_relative 'release_common'
require_relative 'validate_version_number'

# Get argument of new version number
@version = @specified_version

# If no argument, exit
abort("Specify a version number. (e.g. `#{__FILE__} --version 21.0.0`)") if @version.nil?

# Make sure version is a valid version number
unless @version.match(/^[0-9]+\.[0-9]+\.[0-9]+$/)
  abort('Version number must be in the format `x.x.x`, e.g. `ci_scripts/propose.rb 21.0.0`')
end

puts "Proposing version: #{@version}".red

# Create a new branch for the release, e.g. bg/release-9.0.0
@branchname = "releases/#{@version}"

def create_branch
  run_command("git checkout -b #{@branchname}")
end

def update_version
  # Overwrite the VERSION file with version
  File.open('VERSION', 'w') do |f|
    f.write(@version)
  end

  # Call the update version script
  run_command('ci_scripts/update_version.sh')
end

def update_placeholders
  # Replace placeholder version in CHANGELOG.md with this version and date
  update_placeholder(@version, 'CHANGELOG.md')
  update_placeholder(@version, 'MIGRATING.md')
end

def commit_changes
  # Commit and push the changes
  run_command("git add -u &&
    git commit -m \"Update version to #{@version}\"")
end

def push_changes
  run_command("git push origin #{@branchname}") unless @is_dry_run
end

def run_download_localized_strings
  return if @is_dry_run
  `sh ci_scripts/download_localized_strings_from_lokalise.sh`
end

def create_pr
  # Create a new pull request from the branch
  pr_body = %{
  - [ ] Verify CHANGELOG
    - [ ] Ensure notes for this release are not empty
    - [ ] Release date correct?
    - [ ] Version number looks correct?
  - [ ] Verify MIGRATING is updated (if necessary).
  - [ ] Verify the following files are updated to use the new version string:
    - [ ] Version.xcconfig
    - [ ] All *.podspec files
    - [ ] StripeAPIConfiguration+Version.swift
  - [ ] Verify changes to localized strings seem sane (e.g. No major removal of langauges or large removal of strings)
  - [ ] If new directories were added, verify they have been added to the appropriate `*.podspec` "files" section.
  }

  return if @is_dry_run

  pr = @github_client.create_pull_request(
    'stripe/stripe-ios',
    'master',
    @branchname,
    "Release version #{@version}",
    pr_body
  )
end

def propose_release
  return if @is_dry_run

  # Lookup PR
  all_prs = @github_client.pull_requests('stripe/stripe-ios', state: 'open')
  pr = all_prs.find { |pr| pr.head.ref == @branchname }

  # Get list of new directories and save to a temp file
  prev_release_tag = @github_client.latest_release('stripe/stripe-ios').tag_name
  `git fetch origin --tags`
  new_dirs = `ci_scripts/check_for_new_directories.sh HEAD #{prev_release_tag}`
  temp_dir = `mktemp -d`.chomp("\n")
  new_dir_file = File.join_if_safe(temp_dir, "new_directories_#{@version}.txt")
  File.open(new_dir_file, 'w') { |file| file.puts new_dirs }

  rputs "Complete the pull request checklist at #{pr.html_url}"
  rputs "For a list of new directories since tag #{prev_release_tag}, `cat #{new_dir_file}`"
  notify_user
end

steps = [
  method(:validate_version_number),
  method(:create_branch),
  method(:update_version),
  method(:update_placeholders),
  method(:run_download_localized_strings),
  method(:commit_changes),
  method(:push_changes),
  method(:create_pr),
  method(:propose_release)
]
execute_steps(steps, @step_index)

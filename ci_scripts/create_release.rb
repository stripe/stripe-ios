#!/usr/bin/env ruby

require_relative 'release_common'

# Get argument of new version number
@version = @specified_version

# If no argument, exit
abort('Specify a version number. (e.g. `ci_scripts/propose.rb 21.0.0`)') if @version.nil?

# Make sure version is a valid version number
abort('Version number must be in the format `x.x.x`, e.g. `ci_scripts/propose.rb 21.0.0`') unless @version.match(/^[0-9]+\.[0-9]+\.[0-9]+$/)

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

def build_documentation
  # Rebuild documentation
  run_command('ci_scripts/build_documentation.rb')
end

def pod_lint
  pod_lint_common
end

def commit_changes
  # Commit and push the changes
  run_command("git commit -am \"Update version to #{@version}\"")
end

def push_changes
  run_command("git push origin #{@branchname}") unless @is_dry_run
end

def create_pr
  # Create a new pull request from the branch
  pr_body = %{
  - [ ] Verify CHANGELOG is updated with any new features or breaking changes (be thorough when reviewing commit history) 
  - [ ] Verify MIGRATING is updated (if necessary).
  - [ ] Verify the following files are updated to use the new version string:
    - [ ] Version.xcconfig
    - [ ] All *.podspec files
    - [ ] StripeAPIConfiguration+Version.swift
  - [ ] If new directories were added, verify they have been added to the appropriate `*.podspec` "files" section and re-run `pod lib lint`.
  }

  unless @is_dry_run
    pr = @github_client.create_pull_request(
      'stripe-ios/stripe-ios',
      'private',
      @branchname,
      "Release version #{@version}",
      pr_body
    )
  end
end

def check_for_missing_localizations
  # Check for missing localizations (we do this last to batch all the interactive parts to the end)
  missing_localizations = `ci_scripts/check_for_missing_localizations.sh`
  # Output the result of the check
  if $?.exitstatus != 0
    puts missing_localizations
    rputs 'Please file a ticket for these missing localizations at https://go/ask/mobile-sdks'
    notify_user
  else
    rputs 'No missing localizations.'
  end
end

def propose_release
  unless @is_dry_run
    all_prs = @github_client.pull_requests('stripe-ios/stripe-ios', :state => 'open')
    pr = all_prs.find { |pr| pr.head.ref == @branchname }
    rputs "Complete the pull request checklist at #{pr.html_url}, then run `propose_release.rb`"
    notify_user
  end
end

steps = [
  method(:create_branch),
  method(:update_version),
  method(:update_placeholders),
  method(:build_documentation),
  method(:pod_lint),
  method(:commit_changes),
  method(:push_changes),
  method(:create_pr),
  method(:check_for_missing_localizations),
  method(:propose_release)
]
if @step_index > 0
  steps = steps.drop(@step_index)
  rputs "Continuing from step #{@step_index}: #{steps.first.name}"
end

begin
  steps.each do |step|
    rputs "# #{step.name} (step #{@step_index + 1}/#{steps.length})"
    step.call
    @step_index += 1
  end
rescue Exception => e
  rputs "Restart with --continue-from #{@step_index} to re-run from this step."
  raise
end

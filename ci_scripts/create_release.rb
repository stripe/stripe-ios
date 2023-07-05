#!/usr/bin/env ruby

require_relative 'release_common'

verify_xcode_version

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

def regenerate_project_files
  run_command('ci_scripts/delete_project_files.rb')
  puts 'Generating project files'
  run_command('tuist generate -n')
  # Delete xcuserdatad folders.
  puts "Deleting user data files"
  run_command('find Stripe* -type d -name "*.xcuserdatad" -exec rm -r {} +', false)
  run_command('find Example* -type d -name "*.xcuserdatad" -exec rm -r {} +', false)
  run_command('find Testers* -type d -name "*.xcuserdatad" -exec rm -r {} +', false)
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
  # Xcode project files are added to ensure compatibility with Carthage,
  # -f is used because this files are included in .gitignore.
  # Manually add the docs directory to pick up any new docs files generated as part of release
  run_command("git add Stripe.xcworkspace -f &&
    git add Stripe*/*.xcodeproj -f &&
    git add Example/**/*.xcodeproj -f &&
    git add Testers/**/*.xcodeproj -f &&
    git add -u &&
    git commit -m \"Update version to #{@version}\"")
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
  - [ ] If new directories were added, verify they have been added to the appropriate `*.podspec` "files" section.
  }

  unless @is_dry_run
    pr = @github_client.create_pull_request(
      'stripe/stripe-ios',
      'master',
      @branchname,
      "Release version #{@version}",
      pr_body
    )
  end
end

def check_for_missing_localizations
  # Check for missing localizations (we do this last to batch all the interactive parts to the end)
  missing_localizations = `ci_scripts/l10n/check_for_missing_localizations.rb`
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
end

steps = [
  method(:create_branch),
  method(:regenerate_project_files),
  method(:update_version),
  method(:update_placeholders),
  method(:commit_changes),
  method(:push_changes),
  method(:create_pr),
  method(:check_for_missing_localizations),
  method(:propose_release)
]
execute_steps(steps, @step_index)

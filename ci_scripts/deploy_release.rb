#!/usr/bin/env ruby

require_relative 'release_common'

# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
MIN_SUPPORTED_XCODE_VERSION = '13.2.1'


@version = version_from_file

@changelog = changelog(@version)

# Verify that xcode-select -p returns the correct version for building Stripe.xcframework.
unless `xcodebuild -version`.include?("Xcode #{MIN_SUPPORTED_XCODE_VERSION}")
  rputs "Xcode #{MIN_SUPPORTED_XCODE_VERSION} is required to build Stripe.xcframework."
  rputs 'Use `xcode-select -s` to select the correct version, or download it from https://developer.apple.com/download/more/.'
  rputs 'If you believe this is no longer the correct version, update `MIN_SUPPORTED_XCODE_VERSION` above.'
  abort
end

def export_builds
  # Compile the build products: bundle install && ./ci_scripts/export_builds.rb
  run_command('ci_scripts/export_builds.rb')
end

def pod_lint
  pod_lint_common
end

def changedoc_approve
  rputs 'Open the CHANGEDOC ticket for this version: https://go/CHANGEDOC and click the "Approve" button.'
  rputs '(You may need to assign it to yourself first.)'
  notify_user
end

def approve_pr
  rputs 'Open the PR, approve it, and merge it.'
  rputs '(Use \"Create merge commit\" and not \"Squash and merge\")'
  rputs 'Don\'t continue until the PR has been merged into `private`!'
  notify_user
end

def prepare_origins
  # Fetch the latest version of the repo: git fetch origin
  run_command('git fetch origin')
  # Add the public origin if you don't already have it:
  `git remote add public git@github.com:stripe/stripe-ios.git`
  # Fetch the latest version of public: git fetch public
  run_command('git fetch public')
end

def fast_forward_master
  rputs 'About to fast-forward public/master to origin/private.'
  rputs 'Disable "include administrators" in the stripe-ios master branch protection settings: https://github.com/stripe/stripe-ios/settings/branch_protection_rules/193653'
  rputs '(Make sure to re-enable this when done!)'
  notify_user

  # Fast forward public/master to the latest private branch
  run_command('git checkout public/master')
  run_command('git merge --ff-only origin/private')
  run_command('git push public HEAD:master') unless @is_dry_run

  rputs 'Re-enable "include administrators" in the stripe-ios master branch protection settings: https://github.com/stripe/stripe-ios/settings/branch_protection_rules/193653'
  notify_user
end

def push_tag
  unless @is_dry_run
    # Create a signed git tag and push to GitHub: git tag -s X.Y.Z -m "Version X.Y.Z" && git push origin --tags && git push public --tags
    run_command("git tag -s #{@version} -m \"Version #{@version}\"")
    run_command('git push origin --tags')
    run_command('git push public --tags')
  end
end

def create_release
  unless @is_dry_run
    @release = @github_client.create_release(
      'stripe/stripe-ios',
      @version,
      {
        body: @changelog
      }
    )
  end
end

def upload_framework
  unless @is_dry_run
    release = @github_client.latest_release('stripe/stripe-ios')
    @github_client.upload_asset(
      release.url,
      File.open('./build/Stripe.xcframework.zip')
    )
  end
end

def push_cocoapods
  unless @is_dry_run
    # Push the release to the CocoaPods trunk: ./ci_scripts/pod_tools.rb push
    rputs 'Pushing the release to Cocoapods.'
    run_command('ci_scripts/pod_tools.rb push')
  end
end

def sync_owner_list
  unless @is_dry_run
    # Sync the owner list for all pods with the Stripe pod.
    run_command('ci_scripts/pod_tools.rb add-all-owners')
  end
end

def changelog_done
  rputs "Click 'Done' for the release issue at https://go/changedoc"
  notify_user
end

def reply_email
  rputs 'Reply to the mobile-sdk-updates@ email sent by the proposer for this version:'
  rputs 'https://go/mobile-sdk-updates-list'
  puts "Deploy complete: https://github.com/stripe/stripe-ios/releases/tag/#{@version}".magenta
  notify_user

  puts 'Done! Have a nice day!'.green
end

steps = [
  method(:export_builds),
  method(:pod_lint),
  method(:changedoc_approve),
  method(:approve_pr),
  method(:prepare_origins),
  method(:fast_forward_master),
  method(:push_tag),
  method(:create_release),
  method(:upload_framework),
  method(:push_cocoapods),
  method(:sync_owner_list),
  method(:changelog_done),
  method(:reply_email)
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
  rputs "Step failed: #{steps[@step_index].name}"
  rputs "Restart with --continue-from #{@step_index} to re-run from this step."
  raise
end

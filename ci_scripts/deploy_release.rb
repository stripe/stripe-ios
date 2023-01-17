#!/usr/bin/env ruby

require_relative 'release_common'

# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
MIN_SUPPORTED_XCODE_VERSION = '13.2.1'.freeze

# Verify that xcode-select -p returns the correct version for building Stripe.xcframework.
unless `xcodebuild -version`.include?("Xcode #{MIN_SUPPORTED_XCODE_VERSION}")
  rputs "Xcode #{MIN_SUPPORTED_XCODE_VERSION} is required to build Stripe.xcframework."
  rputs 'Use `xcode-select -s` to select the correct version, or download it from https://developer.apple.com/download/more/.'
  rputs "If you believe this is no longer the correct version, update `MIN_SUPPORTED_XCODE_VERSION` in `#{__FILE__}`."
  abort
end

@version = version_from_file

@changelog = changelog(@version)

@cleanup_branchname = "releases/#{@version}_cleanup"

def export_builds
  # Compile the build products: bundle install && ./ci_scripts/export_builds.rb
  run_command('ci_scripts/export_builds.rb')
end

def changedoc_approve
  rputs 'Open the CHANGEDOC ticket for this version: https://go/CHANGEDOC and click the "Approve" button.'
  rputs '(You may need to assign it to yourself first.)'
  notify_user
end

def approve_pr
  rputs 'Open the PR, approve it, and merge it.'
  rputs '(Use "Create merge commit" and not "Squash and merge")'
  rputs 'Don\'t continue until the PR has been merged into `master`!'
  notify_user
end

def create_docs_pr
  unless @is_dry_run
    pr = @github_client.create_pull_request(
      'stripe/stripe-ios',
      'docs',
      "docs-publish/#{@version}",
      "Publish docs for v#{@version}"
    )

    rputs "Docs PR created at #{pr.html_url}"
    rputs 'Request review on the PR and merge it.'
    notify_user
  end
end

def push_tag
  unless @is_dry_run
    # Create a signed git tag and push to GitHub: git tag -s X.Y.Z -m "Version X.Y.Z" && git push origin --tags
    run_command("git tag -s #{@version} -m \"Version #{@version}\"")
    run_command('git push origin --tags')
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
    # Use the reference to the release object from `create_release` if it exists,
    # otherwise fetch it.
    release = @release
    release ||= @github_client.latest_release('stripe/stripe-ios')
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

def push_spm_mirror
  unless @is_dry_run
    rputs 'Pushing the release to our SPM mirror.'
    run_command("ci_scripts/push_spm_mirror.rb --version #{@version}")
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
end

def cleanup_project_files
  rputs 'Cleanup generated project files from repo'
  run_command("git checkout -b #{@cleanup_branchname}")
  run_command('ci_scripts/delete_project_files.rb')
  run_command("git add -u && git commit -m \"Remove generated project files for v#{@version}\"")
end

def create_cleanup_pr
  unless @is_dry_run
    run_command("git push origin #{@cleanup_branchname}")
    pr = @github_client.create_pull_request(
      'stripe/stripe-ios',
      'master',
      @cleanup_branchname,
      "Remove generated project files for v#{@version}"
    )

    rputs "Cleanup PR created at #{pr.html_url}"
    rputs 'Request review on the PR and merge it.'
    notify_user
  end

  puts 'Done! Have a nice day!'.green
end

steps = [
  method(:export_builds),
  method(:changedoc_approve),
  method(:approve_pr),
  method(:create_docs_pr),
  method(:push_tag),
  method(:create_release),
  method(:upload_framework),
  method(:push_cocoapods),
  method(:push_spm_mirror),
  method(:sync_owner_list),
  method(:changelog_done),
  method(:cleanup_project_files),
  method(:create_cleanup_pr)
]
execute_steps(steps, @step_index)

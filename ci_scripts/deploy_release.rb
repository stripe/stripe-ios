#!/usr/bin/env ruby

require_relative 'release_common'
require_relative 'vm_tools'

# This should generally be the minimum Xcode version supported by the App Store, as the
# compiled XCFrameworks won't be usable on older versions.
# We sometimes bump this if an Xcode bug or deprecation forces us to upgrade early.
MIN_SUPPORTED_XCODE_VERSION = '15.0'.freeze

def verify_xcode_version
  # Verify that xcode-select -p returns the correct version for building Stripe.xcframework.
  return if `xcodebuild -version`.include?("Xcode #{MIN_SUPPORTED_XCODE_VERSION}")

  rputs "Xcode #{MIN_SUPPORTED_XCODE_VERSION} is required to build Stripe.xcframework."
  rputs 'Use `xcode-select -s` to select the correct version, or download it from https://developer.apple.com/download/more/.'
  rputs "If you believe this is no longer the correct version, update `MIN_SUPPORTED_XCODE_VERSION` in `#{__FILE__}`."
  abort
end

@version = version_from_file

@changelog = changelog(@version)

@cleanup_branchname = "releases/#{@version}_cleanup"

def export_builds
  verify_xcode_version

  # Delete Stripe.xcframework.zip if one exists
  run_command('rm -f build/Stripe.xcframework.zip')

  run_command('ci_scripts/export_builds.rb')

  raise 'build/Stripe.xcframework.zip not found. Did the build fail?' unless File.exist?('build/Stripe.xcframework.zip')
end

def export_builds_from_xcode_cloud
  return if @is_dry_run
  # Delete Stripe.xcframework.zip if one exists
  run_command('rm -f build/Stripe.xcframework.zip')

  run_command('ci_scripts/export_builds_from_xcode_cloud.rb')

  raise 'build/Stripe.xcframework.zip not found. Did we fail to fetch it from Xcode Cloud?' unless File.exist?('build/Stripe.xcframework.zip')
end

def approve_pr
  rputs 'Open the PR, approve it, and merge it.'
  rputs '(Use "Squash and merge")'
  rputs 'Don\'t continue until the PR has been merged into `master`!'
  notify_user
end

def create_docs_pr
  return if @is_dry_run

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

def push_tag
  return if @is_dry_run

  # Create a signed git tag and push to GitHub: git tag -s X.Y.Z -m "Version X.Y.Z" && git push origin X.Y.Z
  run_command("git tag -s #{@version} -m \"Version #{@version}\"")
  run_command("git push origin #{@version}")
end

def create_release
  return if @is_dry_run

  @release = @github_client.create_release(
    'stripe/stripe-ios',
    @version,
    {
      body: @changelog
    }
  )
end

def upload_framework
  return if @is_dry_run

  # Use the reference to the release object from `create_release` if it exists,
  # otherwise fetch it.
  release = @release
  release ||= @github_client.latest_release('stripe/stripe-ios')
  @github_client.upload_asset(
    release.url,
    File.open('./build/Stripe.xcframework.zip')
  )
end

def push_cocoapods
  return if @is_dry_run

  # Push the release to the CocoaPods trunk: ./ci_scripts/pod_tools.rb push
  rputs 'Pushing the release to Cocoapods.'
  run_command('ci_scripts/pod_tools.rb push')
end

def push_spm_mirror
  return if @is_dry_run

  rputs 'Pushing the release to our SPM mirror.'
  run_command("ci_scripts/push_spm_mirror.rb --version #{@version}")
end

def sync_owner_list
  unless @is_dry_run
    # Sync the owner list for all pods with the Stripe pod.
    run_command('ci_scripts/pod_tools.rb add-all-owners')
  end

  puts 'Done! Have a nice day!'.green
  notify_user
end

steps = [
  method(:export_builds_from_xcode_cloud),
  method(:approve_pr),
  method(:create_docs_pr),
  method(:push_tag),
  method(:create_release),
  method(:upload_framework),
  method(:push_cocoapods),
  method(:push_spm_mirror),
  method(:sync_owner_list)
]
execute_steps(steps, @step_index)

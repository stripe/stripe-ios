#!/usr/bin/env ruby

require_relative 'release_common'
require_relative 'vm_tools'

@version = version_from_file

@changelog = changelog(@version)

@cleanup_branchname = "releases/#{@version}_cleanup"

def export_builds
  # Delete Stripe.xcframework.zip if one exists
  run_command('rm -f build/Stripe.xcframework.zip')

  if @is_dry_run
    # Run locally
    run_command('ci_scripts/export_builds.rb')
  else
    # Run in VM
    if need_to_build_vm?
      build_vm
    end
    bring_up_vm_and_wait_for_boot
    run_command_vm('source ~/.zprofile && sudo gem install bundler:2.1.2 && bundle install && tuist generate -n && bundle exec ./ci_scripts/export_builds.rb')
    finish_vm
  end
  raise 'build/Stripe.xcframework.zip not found. Did the build fail?' unless File.exist?('build/Stripe.xcframework.zip')
end

def approve_pr
  rputs 'Open the PR, approve it, and merge it.'
  rputs '(Use "Squash and merge")'
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
    # Create a signed git tag and push to GitHub: git tag -s X.Y.Z -m "Version X.Y.Z" && git push origin X.Y.Z
    run_command("git tag -s #{@version} -m \"Version #{@version}\"")
    run_command("git push origin #{@version}")
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

def reply_email
  rputs 'Reply to the mobile-sdk-updates@ email sent by the proposer for this version:'
  rputs 'https://go/mobile-sdk-updates-list'
  puts "Deploy complete: https://github.com/stripe/stripe-ios/releases/tag/#{@version}".magenta
  notify_user
end

def cleanup_project_files
  unless @is_dry_run
    rputs 'Cleanup generated project files from repo'
    run_command("git checkout -b #{@cleanup_branchname}")
    run_command("git pull -r origin master")
    run_command('ci_scripts/delete_project_files.rb')
    run_command("git add -u && git commit -m \"Remove generated project files for v#{@version}\"")
  end
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
  method(:approve_pr),
  method(:create_docs_pr),
  method(:push_tag),
  method(:create_release),
  method(:upload_framework),
  method(:push_cocoapods),
  method(:push_spm_mirror),
  method(:sync_owner_list),
  method(:cleanup_project_files),
  method(:create_cleanup_pr)
]
execute_steps(steps, @step_index)

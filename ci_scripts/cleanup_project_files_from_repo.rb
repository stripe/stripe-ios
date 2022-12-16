#!/usr/bin/env ruby

require_relative 'common'

def cleanup_project_files_from_repo(version, github_client)
  branchname = "releases/#{version}_cleanup"
  run_command("git checkout -b #{branchname}")
  run_command('ci_scripts/delete_project_files.rb')
  run_command("git add -u && git commit -m \"Remove generated project files for v#{@version}\"")
  run_command("git push origin #{branchname}")
  github_client.create_pull_request(
    'stripe/stripe-ios',
    'master',
    branchname,
    "Remove generated project files for v#{@version}"
  )

  rputs 'Request review on the PR and merge it.'
  notify_user
end

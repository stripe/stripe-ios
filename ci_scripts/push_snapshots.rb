#!/usr/bin/env ruby
# frozen_string_literal: true

# push_snapshots.rb
#
# Pushes the snapshot commit created by update_snapshots.rb.
# Run this AFTER deploy-to-bitrise-io so artifacts are uploaded
# before the push triggers a new build.

SCRIPT_DIR = __dir__
ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
Dir.chdir(ROOT_DIR)

# Only push if there's a snapshot commit to push
last_message = `git log -1 --format='%s'`.strip
unless last_message == 'Update snapshot reference images'
  puts '==> No snapshot commit to push.'
  exit 0
end

branch = ENV['BITRISE_GIT_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip
if branch == 'HEAD'
  abort 'Error: Could not determine branch name. Set BITRISE_GIT_BRANCH.'
end

puts "==> Pushing snapshot update to #{branch}..."
system('git', 'remote', 'set-url', 'origin', 'git@github.com:stripe/stripe-ios.git')
system('git', 'fetch', 'origin', branch, [:out, :err] => '/dev/null')
system('git', 'rebase', "origin/#{branch}", exception: true)
system('git', 'push', 'origin', "HEAD:#{branch}", exception: true)

puts '==> Done.'

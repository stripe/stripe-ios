#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

# The clone Step checks out the requested commit without merging. Find its real
# merge base by fetching only the two relevant histories, then optionally merge.
# This avoids git-clone's fallback to fetching every branch with --unshallow.
module CIBranch
  def self.git(*args)
    output, error, status = Open3.capture3('git', *args)
    raise "git #{args.first} failed: #{output}\n#{error}" unless status.success?

    output.strip
  end

  def self.prepare(env = ENV)
    head = git('rev-parse', 'HEAD')
    requested = env['BITRISE_GIT_COMMIT'].to_s
    raise 'Checkout does not match the requested commit' unless requested.empty? || requested == head

    branch = env['BITRISEIO_GIT_BRANCH_DEST'].to_s
    branch = 'master' if branch.empty?
    git('check-ref-format', "refs/heads/#{branch}")
    target_ref = "refs/remotes/origin/#{branch}"
    git('fetch', '--no-tags', '--depth=100', 'origin', "+refs/heads/#{branch}:#{target_ref}")
    target = git('rev-parse', target_ref)
    source = env['BITRISEIO_PULL_REQUEST_REPOSITORY_URL'].to_s
    source = 'origin' if source.empty?

    # Fetch by immutable SHA so a push during checkout cannot change the build.
    # GitHub exposes fork PR commits through the source repository as well.
    [100, 500, 2000, 8000].each do |depth|
      output, status = Open3.capture2('git', 'merge-base', head, target)
      if status.success?
        base = output.strip
        puts "CI comparison: #{base}...#{head} (destination #{target})"
        return { head: head, base: base, target: target }
      end

      git('fetch', '--no-tags', "--depth=#{depth}", source, head)
      git('fetch', '--no-tags', "--depth=#{depth}", 'origin', target)
    end

    # Very old PRs still work, without discovering unrelated remote branches.
    if git('rev-parse', '--is-shallow-repository') == 'true'
      git('fetch', '--no-tags', '--unshallow', source, head)
    end
    if git('rev-parse', '--is-shallow-repository') == 'true'
      git('fetch', '--no-tags', '--unshallow', 'origin', target)
    end
    base = git('merge-base', head, target)
    puts "CI comparison: #{base}...#{head} (destination #{target})"
    { head: head, base: base, target: target }
  end

  def self.merge(comparison)
    # Match CI's previous destination-first merge; conflicts remain failures.
    git('checkout', '--detach', comparison.fetch(:target))
    git('-c', 'user.name=Bitrise CI', '-c', 'user.email=mobile-sdk-team@stripe.com',
        'merge', '--no-edit', comparison.fetch(:head))
    puts "Testing merged tree #{git('rev-parse', 'HEAD')}"
  end
end

if $PROGRAM_NAME == __FILE__
  if ENV['BITRISE_PULL_REQUEST'].to_s.empty?
    puts 'Not a pull request; keeping the requested checkout.'
  else
    CIBranch.merge(CIBranch.prepare)
  end
end

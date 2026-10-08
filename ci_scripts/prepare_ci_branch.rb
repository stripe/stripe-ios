#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'

# The clone Step checks out the requested commit without merging. Find its real
# merge base by fetching only the relevant histories, then merge.
# This avoids git-clone's fallback to fetching every branch with --unshallow.
module CIBranch
  # Git's internal "infinite" depth. Unlike --unshallow, it is valid on complete repos.
  MAX_DEPTH = 2_147_483_647
  # Master gets ~130 commits/month, so most PRs resolve in the first one or two fetches.
  FETCH_DEPTHS = [100, 200, 600, MAX_DEPTH].freeze

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
    # Lint compares against origin/master even when the PR targets another branch.
    refspecs = [branch, 'master'].uniq.map { |b| "+refs/heads/#{b}:refs/remotes/origin/#{b}" }

    fetched = nil
    FETCH_DEPTHS.each do |depth|
      # Re-fetching with a larger --depth does not reliably deepen tips we already have,
      # so later attempts deepen the existing history by the difference instead.
      depth_arg = fetched ? "--deepen=#{depth - fetched}" : "--depth=#{depth}"
      fetched = depth
      # Fetch the head by immutable SHA so a push during checkout cannot change the build.
      # GitHub exposes fork PR commits through the destination repository.
      git('fetch', '--no-tags', depth_arg, 'origin', head, *refspecs)
      next unless [target_ref, 'refs/remotes/origin/master'].all? { |ref| merge_base?(head, ref) }

      target = git('rev-parse', target_ref)
      puts "CI comparison: #{git('merge-base', head, target)}...#{head} (destination #{target})"
      return { head: head, target: target }
    end
    raise "#{head} has no merge base with #{target_ref} and origin/master"
  end

  def self.merge_base?(*commits)
    _, status = Open3.capture2('git', 'merge-base', *commits)
    status.success?
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

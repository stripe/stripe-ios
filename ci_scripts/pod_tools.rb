#!/usr/bin/env ruby

# frozen_string_literal: true

require 'cocoapods'
require 'colorize'
require 'mail'
require 'open3'
require 'yaml'
require 'json'

PODSPECS = YAML.load_file('modules.yaml')['pod_push_order']

USAGE = <<~TEXT
  #{'Usage:'.underline}

    #{"#{__FILE__} COMMAND".green}

  #{'Commands:'.underline}

    #{'push'.green}

      Pushes all podspecs to `trunk` in order by dependencies.

    #{'add-all-owners'.green} [#{'POD'.magenta}]

      Adds all the owners of the `Stripe` pod as owners of #{'`POD`'.magenta}.
      If no pod is specified, adds all owners to all pods other than `Stripe`.

    #{'add-owner'.green} #{'OWNER-EMAIL'.magenta}

      Adds the registered user specified with #{'`OWNER-EMAIL`'.magenta} as an
      owner of all pods in this repo.

    #{'remove-owner'.green} #{'OWNER-EMAIL'.magenta}

      Removes the user specified with #{'`OWNER-EMAIL`'.magenta} from being
      owner of all pods in this repo.
TEXT

# Pushes all podspecs to `trunk` in order by dependencies.
def push
  puts "If this is your first time running this command, it's going to take a while."
  puts 'Go for a 🚶 or take a ☕️ break.'
  puts ''
  puts "Pushing the following podspecs to #{'`trunk`'.bold.magenta}: "\
  "#{PODSPECS.map(&:underline).join(' ')}"

  expected_pod_version = File.open('VERSION', &:readline).strip

  PODSPECS.each do |podspec|
    if get_pod_version(podspec) == expected_pod_version
      puts "No need to push: #{podspec}.  Latest version is already #{expected_pod_version}"
    else
      run_retrying("pod trunk push #{podspec} --synchronous", max_retries: 4)
      unless $?.success?
        abort "Unable to push pod #{podspec}.\n"\
              'If the spec failed to validate due to not finding a compatible version of a pod that was just pushed, wait a few minutes and try again.'
      end
    end
  end
end

def capture_retrying(cmd, max_retries: 10)
  retries = 0
  loop do
    stdout, stderr, status = Open3.capture3(cmd)
    if !status.success? && retries <= max_retries
      retries += 1
      delay = [2**retries, 32].min
      puts "Something went wrong. Trying again in #{delay} seconds..."
      sleep(delay)
      puts 'Retrying...'
    else
      return stdout, stderr, status
    end
  end
end

def run_retrying(cmd, max_retries: 10)
  retries = 0
  loop do
    result = system(cmd)
    if !$?.success? && retries <= max_retries
      retries += 1
      delay = [2**retries, 32].min
      puts "Something went wrong. Trying again in #{delay} seconds..."
      sleep(delay)
      puts 'Retrying...'
    else
      return result
    end
  end
end

def get_pod_version(pod)
  stdout, _stderr, status = Open3.capture3("pod spec cat #{pod}")
  return nil unless status.success?

  latest_pod_spec = JSON.parse(stdout)
  latest_pod_spec['version']
end

def get_owners(pod)
  puts "Looking up owners of #{pod.magenta} pod..."
  stdout, stderr, status = capture_retrying("pod trunk info #{pod}")
  abort(stderr.red) unless status.success?

  # Parse output and extract emails
  yaml = YAML.safe_load(stdout.lines[2..-1].join)
  owners = yaml[1]['Owners']

  owners.map { |owner| Mail::Address.new(owner).address }
end

def add_owners(pod, owners)
  abort("Specify a different pod other than #{'Stripe'.magenta}.".red) if pod == 'Stripe'

  pod_owners = get_owners(pod)
  owners_to_be_added = owners - pod_owners

  changes = pod_owners.map { |email| "  #{email}" }

  owners_to_be_added.each do |owner|
    puts "Adding #{owner.blue} to #{pod.magenta} owners."

    _stdout, stderr, status = capture_retrying("pod trunk add-owner #{pod} #{owner}")
    abort(stderr.red) unless status.success?

    changes << "+ #{owner}".green
  end

  puts 'Done updating owners:'
  puts changes.join("\n")
end

# Adds all the owners of the `Stripe` pod as owners of the given pod.
def add_all_owners_all_pods
  pods = all_pods_in_repo - ['Stripe']
  owners = get_owners('Stripe')
  pods.each do |pod|
    add_owners(pod, owners)
  end
end

# Adds the specified registered user as an owner of all pods in this repo.
def add_owner(owner_email)
  all_pods_in_repo.each do |pod|
    puts "Adding #{owner_email.magenta} to #{pod.magenta} owners."
    _stdout, stderr, status = capture_retrying("pod trunk add-owner #{pod} #{owner_email}")
    abort(stderr.red) unless status.success?
  end
end

# Removes the specified user from being an owner of all pods in this repo.
def remove_owner(owner_email)
  all_pods_in_repo.each do |pod|
    puts "Removing #{owner_email.magenta} from #{pod.magenta} owners."
    _stdout, stderr, status = capture_retrying("pod trunk remove-owner #{pod} #{owner_email}")
    abort(stderr.red) unless status.success?
  end
end

# -- Helpers

# Returns a list of all the pods in this repo
def all_pods_in_repo
  Dir.glob('./*.podspec').map { |file| Pod::Specification.from_file(file).root.name }
end

# -- Command Line

if ARGV.empty?
  abort("#{'Please specify a command.'.red}\n\n#{USAGE}")
elsif ARGV[0] == 'push'
  push
elsif ARGV[0] == 'add-all-owners'
  if ARGV.length < 2
    add_all_owners_all_pods
  else
    add_owners(ARGV[1], get_owners('Stripe'))
  end
elsif ARGV[0] == 'add-owner'
  if ARGV.length < 2
    abort("#{'Please specify an owner email to add.'.red}\n\n#{USAGE}")
  else
    add_owner(ARGV[1])
  end
elsif ARGV[0] == 'remove-owner'
  if ARGV.length < 2
    abort("#{'Please specify an owner email to remove.'.red}\n\n#{USAGE}")
  else
    remove_owner(ARGV[1])
  end
else
  abort("#{"#{"'trunk #{ARGV[0]}'".green} is not a recognized command.".red}\n\n#{USAGE}")
end

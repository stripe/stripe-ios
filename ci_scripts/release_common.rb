#!/usr/bin/env ruby

# This is a support file for the other release scripts.

require 'fileutils'
require 'optparse'
require 'colorize'
require 'octokit'
require 'erb'

SCRIPT_DIR = __dir__
abort 'Unable to find SCRIPT_DIR' if SCRIPT_DIR.nil? || SCRIPT_DIR.empty?

ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
abort 'Unable to find ROOT_DIR' if ROOT_DIR.nil? || ROOT_DIR.empty?
ROOT_DIR_PATHNAME = Pathname(ROOT_DIR)

Dir.chdir(ROOT_DIR)

@step_index = 0

OptionParser.new do |opts|
  opts.banner = "Release scripts\n Usage: script.rb [options]"

  opts.on("--version VERSION",
    "Version to release (e.g. 21.2.0)") do |t|
    @specified_version = t
  end

  opts.on("--dry-run", "Don't do any real deployment, just build") do |s|
    @is_dry_run = s
  end

  opts.on("--continue-from NUMBER",
    "Continue from a specified step") do |t|
    @step_index = t.to_i
  end
end.parse!

def notify_user
  puts "Press enter to continue... \a".red
  STDIN.gets unless @is_dry_run
end

def get_current_release_version_of_repo(repo)
  begin
    latest_version = Octokit.latest_release(repo)
    latest_version.tag_name
  rescue
    raise "No releases found."
  end
end

def run_command(command)
  puts "> #{command}".blue
  system("#{command}")
  if $?.exitstatus != 0
    rputs "Command failed: #{command} \a"
    raise
  end
end

def changelog(version)
  changelog = ''
  reading = false
  # Get changelog for version from CHANGELOG
  File.foreach('CHANGELOG.md') do |line|
    # If the line starts with ##, we've reached the end of the entry
    break if reading && line.start_with?('## ')

    # If the line starts with ## and the version, start reading the entry
    reading = true if line.start_with?('## ') && line.include?(version)

    changelog += line if reading
  end
  changelog
end

def update_placeholder(version, filename)
  changelog = IO.readlines(filename).map do |line|
    if line.start_with?('## X')
      "## #{version} #{Time.now.strftime('%Y-%m-%d')}\n"
    elsif line.start_with?('## Migrating from versions < X')
      "## Migrating from versions < #{version}\n"
    else
      line
    end
  end

  File.open(filename, 'w') do |file|
    file.puts changelog
  end
end

def version_from_file
  # Get version from VERSION
  version = ''
  File.open('VERSION', 'r') do |f|
    version = f.read.chomp
  end
  version
end

def rputs(string)
  puts string.red
end

def github_login
  token = `fetch-password -q bindings/gh-tokens/$USER`
  if $?.exitstatus != 0
    puts "Couldn't fetch GitHub token. Follow the iOS SDK Deploy Guide (https://go/ios-sdk-deploy) to set up a token. \a".red
    exit(1)
  end
  client = Octokit::Client.new(access_token: token)
  abort('Invalid GitHub token. Follow the wiki instructions for setting up a GitHub token.') unless client.login 
  client
end

def pod_lint_common
  # Validate the Stripe pods
  run_command('pod lib lint --include-podspecs=\'*.podspec\'')
end

@github_client = github_login unless @is_dry_run

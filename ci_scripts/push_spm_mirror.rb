#!/usr/bin/env ruby

require_relative 'release_common'
require 'tmpdir'
require 'yaml'

# Get argument of new version number
@version = @specified_version

# If no argument, exit
abort("Specify a version number. (e.g. `#{__FILE__} --version 21.0.0`)") if @version.nil?

# Make sure version is a valid version number
abort('Version number must be in the format `x.x.x`, e.g. `ci_scripts/push_spm_mirror.rb 21.0.0`') unless @version.match(/^[0-9]+\.[0-9]+\.[0-9]+$/)

puts "Creating SPM mirror tag for version: #{@version}".red

# Create a new temporary directory
Dir.mktmpdir do |tmp_dir|
  # create a temporary clone of stripe-ios-spm
  full_repo_dir = tmp_dir + '/stripe-ios'
  spm_repo_dir = tmp_dir + '/stripe-ios-spm'
  run_command("rsync -av  . #{full_repo_dir}")
  run_command("git clone https://github.com/stripe/stripe-ios-spm #{spm_repo_dir}")
  
  Dir.chdir(full_repo_dir) do
    run_command("git checkout #{@version}")
    run_command('git clean -fdx')
  
    files_to_copy = [
      'Stripe3DS2',
      'CHANGELOG.md',
      'MIGRATING.md',
      'README.md',
      'VERSION',
      'Package.swift'
    ]
    # get the list of frameworks from the yaml
    modules = YAML.load_file('modules.yaml')['modules']
    modules.each do |m|
      # add the folder for each framework name, plus other required SPM folders and files
      files_to_copy.append(m['framework_name'])
    end

    # copy files_to_copy to stripe-ios-spm
    files_to_copy.each do |f|
      FileUtils.copy_entry(f, spm_repo_dir + '/' + f)
    end
  end

  Dir.chdir(tmp_dir + '/stripe-ios-spm') do
    run_command('git add .')
    run_command("git commit -m \"Stripe SDK #{@version}\"")
    run_command("git tag #{@version}")
    run_command('git push origin --tags')
  end

  changelog = changelog(@version)

  unless @is_dry_run
    @release = @github_client.create_release(
      'stripe/stripe-ios-spm',
      @version,
      {
        body: changelog
      }
    )
  end

  puts "Deployed SPM mirror to stripe-ios-spm"
end

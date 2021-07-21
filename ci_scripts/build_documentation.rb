#!/usr/bin/env ruby

require 'rubygems/dependency_installer.rb'
require 'cocoapods'
require 'fileutils'
require 'optparse'
require 'yaml'

script_dir = __dir__

def info(string)
  puts "[#{File.basename(__FILE__)}] [INFO] #{string}"
end

def die(string)
  abort "[#{File.basename(__FILE__)}] [ERROR] #{string}"
end

def install_jazzy(version = Gem::Requirement.default)
  begin
    installer = Gem::DependencyInstaller.new
    installer.install("jazzy", version)
  rescue
    die "Executing \`gem install jazzy\` failed"
  end
end

# Note(mludowise): When `check_documentation.sh` locally, we want to save docs
# to a temp directory so we can check undocumented.json and grep for `@_spi`,
# without unintentially committing changes to the `/docs` folder.
docs_root_directory = File.expand_path("#{script_dir}/..", Dir.getwd)
OptionParser.new do |opts|
  opts.on("--docs-root-dir DIRECTORY", "Generate docs to this directory instead of the repo's root directory.") do |dir|
    docs_root_directory = File.expand_path(dir, Dir.getwd)
  end
end.parse!

# Verify jazzy is installed
begin
  Gem::Specification.find_by_name('jazzy')
rescue
  if ENV["CI"] != 'true'
    die "Please install jazzy: https://github.com/realm/jazzy#installation"
  end

  info "Installing jazzy..."
  install_jazzy
end

# Verify jazzy is up to date
jazzy_version_local = Gem::Specification.find_by_name('jazzy').version
fetcher = Gem::SpecFetcher.fetcher
newer_jazzy_dependency = Gem::Dependency.new "jazzy", "> #{jazzy_version_local}"
newer_jazzy_remotes, = fetcher.search_for_dependency newer_jazzy_dependency
unless newer_jazzy_remotes.empty?
  jazzy_version_remote  = newer_jazzy_remotes.map { |n, _| n.version }.sort.last
  info "Current jazzy version: #{jazzy_version_local}"

  if ENV["CI"] != 'true'
    die "Please update jazzy: \`gem update jazzy\`"
  end

  info "Updating jazzy to version #{jazzy_version_remote}..."
  install_jazzy ">= #{jazzy_version_remote}"
end

# Create temp podspec directory
# NOTE(mludowise|https://github.com/realm/jazzy/issues/1262):
# This won't be needed if jazzy ever allows for multiple development pods
make_dir_output = `#{script_dir}/make_temp_spec_repo.sh`
make_dir_status=$?.exitstatus

unless make_dir_status == 0
  die temp_spec_dir
end

temp_spec_dir = `#{script_dir}/make_temp_spec_repo.sh`.lines.last.strip
info "Sucessfully created podspec repo at \`#{temp_spec_dir}\`"

# Clean pod cache to always use latest local copy of pod dependencies
# NOTE(mludowise|https://github.com/realm/jazzy/issues/1262):
# This won't be needed if jazzy ever allows for multiple development pods
info "Cleaning pod cache..."
Dir.glob("#{script_dir}/../*.podspec").each do |file|
  podspec = Pod::Specification.from_file(file)
  cmd = Pod::Command::Cache::Clean.new(CLAide::ARGV.new([podspec.name, '--all']))
  cmd.run
end

# Execute jazzy
modules = YAML.load_file("modules.yaml")['modules']
release_version = `cat "#{script_dir}/../VERSION"`.strip
jazzy_exit_code = 0

modules.each do |m|
  docs_config = m['docs']
  if docs_config.nil?
    next
  end

  # Note: If we don't check for empty string/nil, then jazzy will silently
  # overwrite the entire git repo directory.
  output = docs_config['output'].to_s
  if output.empty?
    die "Missing required docs config \`output\`. Update modules.yaml."
  end

  # Prepend `docs_root_directory`
  output =  File.expand_path(output, docs_root_directory).to_s

  info "Executing jazzy for #{m['podspec']}..."
  `jazzy \
    --config "#{script_dir}/../.jazzy.yaml" \
    --output "#{output}" \
    --github-file-prefix "https://github.com/stripe/stripe-ios/tree/#{release_version}" \
    --podspec "#{script_dir}/../#{m['podspec']}" \
    --pod-sources "file://#{temp_spec_dir}"`

  # Verify jazzy exit code
  jazzy_exit_code=$?.exitstatus

  break if jazzy_exit_code != 0

end

# Cleanup temp podspec directory
FileUtils.rm_rf(temp_spec_dir)

if jazzy_exit_code != 0
  die "Executing jazzy failed with status code: #{jazzy_exit_code}"
end

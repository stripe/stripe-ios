#!/usr/bin/env ruby

require 'cocoapods'
require 'jazzy'
require 'fileutils'
require 'mustache'
require 'optparse'
require 'pathname'
require 'tempfile'
require 'yaml'

# Redefine backtick to exit the script on failure.
# This is basically `set -e`, but Ruby.
define_method :'`' do |*args|
  puts "> #{args}"
  output = Kernel.send('`', *args)
  exit $?.exitstatus unless $?.success?
  return output
end

def info(string)
  puts "[#{File.basename(__FILE__)}] [INFO] #{string}"
end

def die(string)
  abort "[#{File.basename(__FILE__)}] [ERROR] #{string}"
end

# Joins the given strings. If one or more arguments is nil or empty, an exception is raised.
def File.join_if_safe(arg1, *otherArgs)
  args = [arg1] + otherArgs

  # Check for empty or nil strings
  args.each do |arg|
    raise 'Cannot join nil or empty string.' if arg.nil? || arg.empty?
  end

  File.join(args)
end

# MARK: - constants

$SCRIPT_DIR = __dir__
$ROOT_DIR = File.expand_path('..', $SCRIPT_DIR)
$JAZZY_CONFIG_FILE = File.join_if_safe($ROOT_DIR, '.jazzy.yaml')
$JAZZY_CONFIG = YAML.load_file($JAZZY_CONFIG_FILE)
$TEMP_DIR = Dir.mktmpdir('stripe-docs')
$TEMP_BUILD_DIR = Dir.mktmpdir('stripe-docs-build')
$TEMP_PUBLISH_DIR = Dir.mktmpdir('stripe-docs-publish')
$ALL_MODULES = YAML.load_file(File.join_if_safe($ROOT_DIR, 'modules.yaml'))['modules']
# The base path for the generated docs: e.g. https://stripe.dev/stripe-ios
$HOSTING_BASE_PATH = '/stripe-ios/'

# Cleanup
at_exit { FileUtils.remove_entry($TEMP_DIR) }

# MARK: - build docs

docs_root_directory = $TEMP_PUBLISH_DIR
should_publish = false

OptionParser.new do |opts|
  opts.on('--docs-root-dir DIRECTORY', "Generate docs to this directory instead of the repo's root directory.") do |dir|
    docs_root_directory = File.expand_path(dir, Dir.getwd)
  end
  opts.on('--publish', 'Publish docs to GitHub') do |b|
    should_publish = b
  end
end.parse!

# Clean up docs
def clean_existing_docs(docs_root_directory)
  docs_dir = File.expand_path('docs', docs_root_directory)
  FileUtils.remove_entry_secure(docs_dir) if File.exist?(docs_dir)
  FileUtils.mkdir_p(docs_dir)
end

def docs_title(release_version)
  "Stripe iOS SDKs #{release_version}"
end

# Relative links in markdown files are broken when they're displayed in our
# docs because the path doesn't exist in the docs site but rather in our
# github repo. This method creates a temporary copy of the README file and fixes
# all the relative links to include a github.com URL prefix.
# It also fixes up some attributes that cause issues with docc.
#
# - readme_file: Path to the readme markdown file.
# - github_file_prefix: GitHub URL prefix linking to source for tag
#   corresponding to this release.
# - github_raw_file_prefix: GitHub URL prefix linking to raw files for the tag
#   corresponding to this release. This is used for `<img/>` tag 'src'.
# - module_name: The module name for this doc file
#
# Returns the path to the temp README file. This file should be deleted after
# generating docs.
def copy_readme_and_fix_relative_links(readme_file, github_file_prefix, github_raw_file_prefix, module_name)
  # Find the relative path of the README so we update the URL prefix accordingly
  relative_readme_pathname = Pathname.new(readme_file).relative_path_from(Pathname.new("#{$SCRIPT_DIR}/.."))
  path = relative_readme_pathname.dirname.to_s
  url_prefix = "#{github_file_prefix}/#{path}"
  url_raw_prefix = "#{github_raw_file_prefix}/#{path}"

  # Read README file
  text = File.read(readme_file)

  # Replace the level 1 heading with the module name in docc's required ``ModuleName`` format
  # Without this, docc will treat this as a regular article instead of a landing page.
  new_contents = text.gsub(/^# .*/, "# ``#{module_name}``")

  # Remove any GitHub badges ([![), they don't render well
  new_contents = new_contents.gsub(/^\[\!\[.*/, '')

  # Remove extraneous level 1 headings, they cause issues
  new_contents = new_contents.gsub(/^===.*/, '')

  # Prepend markdown links with the `url_prefix` that don't start with
  # "http://", "https://", "mailto:", or "#"
  new_contents = new_contents.gsub(%r{\]\(((?!https\://)(?!http\://)(?!mailto\:)[^#].*?)\)}, "](#{url_prefix}/\\1)")

  # Prepend `<a/>` tag 'href' attributes with the `url_prefix` that don't start
  # with "http://", "https://", "mailto:", or "#"
  new_contents = new_contents.gsub(%r{<a\s+(.+\s)*?href=("|')((?!https\://)(?!http\://)(?!mailto\:)[^#].*?)("|')}, "<a \\href='#{url_prefix}/\\3'")

  # Prepend `<img/>` tag 'src' attributes with the `url_prefix` that don't start
  # with "http://" or "https://"
  new_contents = new_contents.gsub(%r{<img\s+(.+\s)*?src=("|')((?!https\://)(?!http\://).*?)("|')}, "<img \\1src='#{url_raw_prefix}/\\3'")

  # Create temp file & write updated contents to it
  new_file = Tempfile.new('README.md')
  File.open(new_file.path, 'w') { |file| file.puts new_contents }

  new_file.path
end

# Execute xcodebuild docbuild
def build_module_docs(modules, release_version, docs_root_directory)
  github_file_prefix = "https://github.com/stripe/stripe-ios/tree/#{release_version}"
  github_raw_file_prefix = "https://github.com/stripe/stripe-ios/raw/#{release_version}"
  jazzy_exit_code = 0

  modules.each do |m|
    # Note: If we don't check for empty string/nil, we might silently
    # overwrite the entire git repo directory.
    output = m['docs']['output'].to_s
    die "Missing required docs config \`output\`. Update modules.yaml." if output.empty?

    # If a readme was specified in modules.yaml, build a docc bundle to set it as a landing page
    readme = m['docs']['readme'].to_s
    docc_container = "#{$ROOT_DIR}/#{m['framework_name']}/#{m['scheme']}/Docs.docc"
    unless readme.empty?
      readme_temp_file_generated = copy_readme_and_fix_relative_links(File.expand_path(readme, "#{$SCRIPT_DIR}/..").to_s, github_file_prefix, github_raw_file_prefix, m['framework_name'])
      readme_temp_file = "#{docc_container}/#{m['framework_name']}.md"
      `mkdir -p #{docc_container}`
      `mv '#{readme_temp_file_generated}' '#{readme_temp_file}'`
    end

    info "Executing xcodebuild for #{m['framework_name']}..."

    # Regenerate the project after adding the docc bundle
    `tuist generate -n`

    # Build the docs
    puts `xcodebuild docbuild \
     -scheme #{m['scheme']} \
     -destination "generic/platform=iOS" \
     -sdk iphoneos \
     -configuration Release \
     -derivedDataPath "#{$TEMP_BUILD_DIR}" \
     OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path #{$HOSTING_BASE_PATH}#{m['framework_name'].downcase}/"`

    # Delete temp readme docc
    FileUtils.remove_entry_secure(docc_container) if File.exist?(docc_container)

    # Verify exit code
    xcodebuild_exit_code = $?.exitstatus

    die "Executing xcodebuild failed with status code: #{jazzy_exit_code}" if jazzy_exit_code != 0
    `mv #{$TEMP_BUILD_DIR}/Build/Products/Release-iphoneos/#{m['framework_name']}.doccarchive #{docs_root_directory}/docs/#{m['framework_name'].downcase}`
    # Clean up the bogus index.html file created by DocC
    File.delete("#{docs_root_directory}/docs/#{m['framework_name'].downcase}/index.html")
  end
end

# Creates an index page that lists all modules with docs enabled and links to their docs
# directory. The descriptions of the modules are from their podspec summaries.
def build_index_page(modules, release_version, docs_root_directory)
  # Copy the docc bundle template
  temp_docc_dir = Dir.mktmpdir('stripe-docs-index-build')
  `rsync -av "#{$SCRIPT_DIR}/docs/Stripe.docc" "#{temp_docc_dir}/"`
  index_path = "#{temp_docc_dir}/Stripe.docc/Stripe.md"
  # Add the `@TechnologyRoot` attribute, which instructs docc to make this the landing page.
  index_content = ''"
  # Stripe iOS SDKs

  @Metadata {
    @TechnologyRoot
  }

  Version #{release_version}

  ## Modules

  "''
  # Add the modules to the docc template
  modules.each do |m|
    # Load podspec to get module name and summary
    podspec = Pod::Specification.from_file(File.join_if_safe($ROOT_DIR, m['podspec']))
    index_content += "**[#{podspec.name}](#{$HOSTING_BASE_PATH}#{m['framework_name'].downcase}/documentation/#{m['framework_name'].downcase})**\n\n#{podspec.summary}\n\n"
  end

  File.write(index_path, index_content)
  # Build it
  `$(xcrun --find docc) \
   convert "#{temp_docc_dir}/Stripe.docc" \
   --output-path "#{temp_docc_dir}/build" \
   --transform-for-static-hosting \
   --hosting-base-path #{$HOSTING_BASE_PATH}`

  `rsync -av "#{temp_docc_dir}/build/"* "#{docs_root_directory}/docs/"`
  # Copy 404 redirect page
  `cp "#{$SCRIPT_DIR}/docs/404.html" "#{docs_root_directory}/docs/404.html"`

  # HACK: Remove all deprecation warnings.
  # Remove this once DocC is fixed: https://github.com/apple/swift-docc/issues/450
  js_files = Dir.glob("#{docs_root_directory}/docs/**/*.json")
  js_files.each do |jsf|
    content = File.read(jsf)
    content = content.gsub(/"deprecated":true/, '"deprecated":false')
    File.open(jsf, 'w') { |file| file.puts content }
  end

  # Clean up the bogus index.html file created by DocC
  File.delete("#{docs_root_directory}/docs/index.html")
end

def publish(release_version, docs_root_directory)
  git_publish_dir = Dir.mktmpdir('stripe-docs-git')
  docs_branchname = "docs-publish/#{release_version}"
  `cp -a "#{$ROOT_DIR}/.git" "#{git_publish_dir}"`
  Dir.chdir(git_publish_dir) do
    `git checkout docs`
  end
  `cp -a "#{docs_root_directory}/docs/"* "#{git_publish_dir}/"`
  Dir.chdir(git_publish_dir) do
    `git checkout -b #{docs_branchname}`
    `git add . && git commit -m "Update docs for #{release_version}"`
    # Overwrite the existing branch for this version
    `git remote set-url origin git@github.com:stripe/stripe-ios.git`
    `git push -f origin #{docs_branchname}`
  end
end

# MARK: - main

clean_existing_docs(docs_root_directory)

# Load modules from yaml and filter out any which don't have docs configured
modules = $ALL_MODULES.select { |m| !m['docs'].nil? }
release_version = `cat "#{$ROOT_DIR}/VERSION"`.strip
build_module_docs(modules, release_version, docs_root_directory)
build_index_page(modules, release_version, docs_root_directory)
publish(release_version, docs_root_directory) if should_publish

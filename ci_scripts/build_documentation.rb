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
    raise "Cannot join nil or empty string." if arg.nil? || arg.empty?
  end

  return File.join(args)
end

# MARK: - constants

$SCRIPT_DIR = __dir__
$ROOT_DIR = File.expand_path("..", $SCRIPT_DIR)
$JAZZY_CONFIG_FILE = File.join_if_safe($ROOT_DIR, ".jazzy.yaml")
$JAZZY_CONFIG = YAML.load_file($JAZZY_CONFIG_FILE)
$TEMP_DIR = Dir.mktmpdir('stripe-docs')

# Cleanup
at_exit { FileUtils.remove_entry($TEMP_DIR) }

# MARK: - build docs

# Note(mludowise): When `check_documentation.sh` locally, we want to save docs
# to a temp directory so we can check undocumented.json and grep for `@_spi`,
# without unintentially committing changes to the `/docs` folder.
def get_docs_root_directory
  docs_root_directory = $ROOT_DIR

  OptionParser.new do |opts|
    opts.on("--docs-root-dir DIRECTORY", "Generate docs to this directory instead of the repo's root directory.") do |dir|
      docs_root_directory = File.expand_path(dir, Dir.getwd)
    end
  end.parse!

  return docs_root_directory
end

def docs_title(release_version)
 return "Stripe iOS SDKs #{release_version}"
end

# Relative links in markdown files are broken when they're displayed in our
# jazzy docs because the path doesn't exist in the docs site but rather in our
# github repo. This method creates a temporary copy of the README file and fixes
# all the relative links to include a github.com URL prefix.
#
# - readme_file: Path to the readme markdown file.
# - github_file_prefix: GitHub URL prefix linking to source for tag
#   corresponding to this release.
# - github_raw_file_prefix: GitHub URL prefix linking to raw files for the tag
#   corresponding to this release. This is used for `<img/>` tag 'src'.
#
# Returns the path to the temp README file. This file should be deleted after
# generating docs.
def copy_readme_and_fix_relative_links(readme_file, github_file_prefix, github_raw_file_prefix)
  # Find the relative path of the README so we update the URL prefix accordingly
  relative_readme_pathname = Pathname.new(readme_file).relative_path_from(Pathname.new("#{$SCRIPT_DIR}/.."))
  path = relative_readme_pathname.dirname.to_s
  url_prefix = "#{github_file_prefix}/#{path}"
  url_raw_prefix = "#{github_raw_file_prefix}/#{path}"

  # Read README file
  text = File.read(readme_file)

  # Prepend markdown links with the `url_prefix` that don't start with
  # "http://", "https://", "mailto:", or "#"
  new_contents = text.gsub(/\]\(((?!https\:\/\/)(?!http\:\/\/)(?!mailto\:)[^#].*?)\)/, "](#{url_prefix}/\\1)")

  # Prepend `<a/>` tag 'href' attributes with the `url_prefix` that don't start
  # with "http://", "https://", "mailto:", or "#"
  new_contents = new_contents.gsub(/<a\s+(.+\s)*?href=("|')((?!https\:\/\/)(?!http\:\/\/)(?!mailto\:)[^#].*?)("|')/, "<a \\href='#{url_prefix}/\\3'")

  # Prepend `<img/>` tag 'src' attributes with the `url_prefix` that don't start
  # with "http://" or "https://"
  new_contents = new_contents.gsub(/<img\s+(.+\s)*?src=("|')((?!https\:\/\/)(?!http\:\/\/).*?)("|')/, "<img \\1src='#{url_raw_prefix}/\\3'")

  # Create temp file & write updated contents to it
  new_file = Tempfile.new('README.md')
  File.open(new_file.path, "w") { |file| file.puts new_contents }

  return new_file.path
end

# Runs SourceKitten and returns the absolute paths to the generated files.
def run_sourcekitten(sdk_module)
  schemes = []
  schemes << sdk_module['scheme']

  if sdk_module['docs'].key?('include')
    schemes << sdk_module['docs']['include']
    schemes.flatten!
  end

  sourcekitten_files = []

  schemes.each do |s|
    output_file = File.join_if_safe($TEMP_DIR, "#{s}.json")

    `sourcekitten doc -- archive -workspace Stripe.xcworkspace -destination 'generic/platform=iOS' -scheme #{s} > #{output_file}`

    sourcekitten_files << output_file
  end

  sourcekitten_files
end

# Execute jazzy
def build_module_docs(modules, release_version, docs_root_directory)
  github_file_prefix = "https://github.com/stripe/stripe-ios/tree/#{release_version}"
  github_raw_file_prefix = "https://github.com/stripe/stripe-ios/raw/#{release_version}"
  jazzy_exit_code = 0

  modules.each do |m|
    # Note: If we don't check for empty string/nil, then jazzy will silently
    # overwrite the entire git repo directory.
    output = m['docs']['output'].to_s
    if output.empty?
      die "Missing required docs config \`output\`. Update modules.yaml."
    end

    sourcekitten_files = run_sourcekitten(m)

    # Prepend `docs_root_directory`
    output = File.expand_path(output, docs_root_directory).to_s

    # If no readme was specified in modules.yaml, let jazzy do it's default thing
    readme = m['docs']['readme'].to_s
    readme_args = ""
    readme_temp_file = nil
    unless readme.empty?
      readme_temp_file = copy_readme_and_fix_relative_links(File.expand_path(readme, "#{$SCRIPT_DIR}/..").to_s, github_file_prefix, github_raw_file_prefix)
      readme_args = "--readme '#{readme_temp_file}'"
    end

    info "Executing jazzy for #{m['framework_name']}..."
    `jazzy \
      --config "#{$JAZZY_CONFIG_FILE}" \
      --output "#{output}" \
      #{readme_args} \
      --github-file-prefix "#{github_file_prefix}" \
      --title "#{docs_title(release_version)}" \
      --module #{m['framework_name']} \
      --sourcekitten-sourcefile "#{sourcekitten_files.join(',')}" \
      --xcodebuild-arguments -destination,'generic/platform=iOS'`

    # Delete temp readme file
    unless readme_temp_file.nil? || !File.exist?(readme_temp_file)
      File.delete(readme_temp_file)
    end

    # Verify jazzy exit code
    jazzy_exit_code=$?.exitstatus

    if jazzy_exit_code != 0
      die "Executing jazzy failed with status code: #{jazzy_exit_code}"
    end
  end
end

# Creates html that lists all modules with docs enabled and links to their docs
# directory. The descriptions of the modules are from their podspec summaries.
def index_page_content(modules)
  view = Mustache.new
  view.template_file = File.join_if_safe($ROOT_DIR, $JAZZY_CONFIG['theme'], "templates", "index.mustache")

  view[:modules] = modules.map do |m|
    # Get get module's docs output relative to `docs` folder
    relative_path = Pathname.new(m['docs']['output']).relative_path_from(Pathname.new('docs'))

    # Load podspec to get module name and summary
    podspec = Pod::Specification.from_file(File.join_if_safe($ROOT_DIR, m['podspec']))

    props={}
    props[:name] = podspec.name
    props[:summary] = podspec.summary
    props[:directory] = relative_path.to_s
    props
  end

  return view.render
end

# Builds the `/docs/index.html` page
def build_index_page(modules, release_version, docs_root_directory)
  info "Building index page..."

  # Reuse Jazzy theme so it's visually consistent with the reset of the docs
  view = Mustache.new
  view.template_name = "doc"
  view.template_path = File.join_if_safe($ROOT_DIR, $JAZZY_CONFIG['theme'], "templates")

  # Add properties expected by template
  # Copied & modified from https://github.com/realm/jazzy
  config = YAML.load_file(File.join_if_safe($ROOT_DIR, ".jazzy.yaml"))
  view[:copyright] = (
    date = DateTime.now.strftime('%Y-%m-%d')
    year = date[0..3]
    "&copy; #{year} <a class=\"link\" href=\"#{$JAZZY_CONFIG['author_url']}\"" \
    "target=\"_blank\" rel=\"external\">#{$JAZZY_CONFIG['author']}</a>. " \
    "All rights reserved. (Last updated: #{date})"
  )
  view[:jazzy_version] = Jazzy::VERSION
  view[:objc_first] = false
  view[:language_stub] = 'swift'
  view[:disable_search] = false
  view[:docs_title] = docs_title(release_version)
  view[:module_version] = release_version
  view[:github_url] = $JAZZY_CONFIG['github_url']
  view[:name] = docs_title(release_version)

  # Don't render search since it won't work for the index page
  view[:disable_search] = true

  # Custom template var for our theme to disable some html for the root index page
  view[:is_root_index] = true

  # Insert generated html
  view[:overview] = index_page_content(modules)

  # Write to docs/index.html
  output_file = File.join_if_safe(docs_root_directory, "docs", "index.html")
  File.open(output_file, 'w') { |file| file.write(view.render) }
end

# Jazzy compiles assets from the theme's assets directory and saves them to each
# module's docs directory. We're going to move one set of them to the docs/ root
# directory and symlink the rest. It's a bit hacky but it reduces duplicate
# css/js/images in our repo and moves it to an expected location that
# docs/index.html wants.
def fix_assets(modules, docs_root_directory)
  docs_dir = File.expand_path('docs', docs_root_directory)

  # Get list of assets used by theme (js, img, css, etc)
  Dir.glob(File.join_if_safe($ROOT_DIR, $JAZZY_CONFIG['theme'], "assets", "*")).each do |asset_file|
    asset_base_name = File.basename(asset_file)

    # Delete old asset copies from /docs directory
    FileUtils.rm_rf(File.join_if_safe(docs_dir, asset_base_name))

    modules.each_with_index do |m, index|
      module_docs_dir = File.join_if_safe(docs_root_directory, m['docs']['output'])
      compiled_asset_path = File.join_if_safe(module_docs_dir, asset_base_name)
      module_asset_path = File.join_if_safe(docs_dir, asset_base_name)

      if index == 0
        # Move the compiled asset from the module's docs folder into `/docs` so index.html can use it
        FileUtils.mv(compiled_asset_path, module_asset_path)
      else
        # Delete the compiled asset from the module's docs folder
        FileUtils.rm_rf(compiled_asset_path)
      end

      # Get the asset folder path relative to the module's docs folder
      relative_asset_path = Pathname.new(module_asset_path).relative_path_from(Pathname.new(module_docs_dir))

      # Symlink so each module's docs folder can use root `/docs` folder's assets
      Dir.chdir(module_docs_dir) {
        File.symlink(relative_asset_path, asset_base_name)
      }
    end
  end
end

# MARK: - main

docs_root_directory = get_docs_root_directory()

# Load modules from yaml and filter out any which don't have docs configured
modules = YAML.load_file(File.join_if_safe($ROOT_DIR, "modules.yaml"))['modules'].select { |m| !m['docs'].nil? }
release_version = `cat "#{$ROOT_DIR}/VERSION"`.strip
build_module_docs(modules, release_version, docs_root_directory)
build_index_page(modules, release_version, docs_root_directory)
fix_assets(modules, docs_root_directory)

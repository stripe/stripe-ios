#!/usr/bin/env ruby
# frozen_string_literal: true

# record_snapshots.rb
#
# Records snapshot tests, compares against the existing reference images using
# a pixel-difference threshold, and updates only meaningful changes.
#
# Usage:
#   ruby ci_scripts/record_snapshots.rb           # Record, compare, update reference images
#   ruby ci_scripts/record_snapshots.rb --commit  # Also commit (for CI)
#   ruby ci_scripts/record_snapshots.rb --dry-run # Show what would change without updating
#
# Requires: ImageMagick (brew install imagemagick)

require 'fileutils'
require 'optparse'

SCRIPT_DIR = __dir__
ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
Dir.chdir(ROOT_DIR)

DEVICE_MODEL = 'iPhone 12 mini'
DEFAULT_VERSIONS = ['16.4']
RECORD_DIR = '/tmp/snapshot-records'
REFERENCE_DIR = File.join(ROOT_DIR, 'Tests/ReferenceImages_64')
DIFF_THRESHOLD = 0.1 # percentage of pixels that must differ
FUZZ = '5%' # per-pixel color tolerance before counting as different

commit = false
dry_run = false
versions = []
OptionParser.new do |opts|
  opts.banner = "Usage: record_snapshots.rb [options]"
  opts.on('--commit', 'Commit changes (for CI)') { commit = true }
  opts.on('--dry-run', 'Show what would change without updating') { dry_run = true }
  opts.on('--version VERSION', 'iOS version to record (can be specified multiple times)') { |v| versions << v }
end.parse!

versions = DEFAULT_VERSIONS if versions.empty?

def require_imagemagick!
  unless system('command', '-v', 'compare', [:out, :err] => '/dev/null')
    abort 'Error: ImageMagick is required. Run: brew install imagemagick'
  end
end

def significant_difference?(file_a, file_b)
  num_diff = `compare -metric AE -fuzz #{FUZZ} '#{file_a}' '#{file_b}' /dev/null 2>&1`.strip.to_i
  total_pixels = `identify -format '%[fx:w*h]' '#{file_a}' 2>/dev/null`.strip.to_i
  return true if total_pixels == 0

  (num_diff.to_f / total_pixels * 100) > DIFF_THRESHOLD
end

require_imagemagick!

# Skip if the last commit is already a snapshot update from CI (prevents infinite loops)
if commit
  last_commit_author = `git log -1 --format='%an'`.strip
  last_commit_message = `git log -1 --format='%s'`.strip
  if last_commit_author == 'Bitrise CI' && last_commit_message == 'Update snapshot reference images'
    puts '==> Last commit is a snapshot update — skipping to avoid loop.'
    exit 0
  end
end

# Maps rel_path -> recorded absolute path for changed/added files
changed_files = {}
added_files = {}
FileUtils.rm_rf('/tmp/snapshot-all-recorded')

versions.each do |os_version|
  puts "==> Recording snapshots (iOS #{os_version})..."

  # Ensure the simulator exists for this version
  existing = `xcrun simctl list devices "#{DEVICE_MODEL}" available`.strip
  unless existing.include?(os_version)
    # Runtime IDs use major.minor only (e.g., iOS-26-4 for 26.4.1)
    major_minor = os_version.split('.')[0..1].join('-')
    runtime = "com.apple.CoreSimulator.SimRuntime.iOS-#{major_minor}"
    device_type = 'com.apple.CoreSimulator.SimDeviceType.iPhone-12-mini'
    puts "    Creating #{DEVICE_MODEL} simulator for iOS #{os_version} (runtime: #{runtime})..."
    system('xcrun', 'simctl', 'create', DEVICE_MODEL, device_type, runtime, exception: true)
  end

  FileUtils.rm_rf(RECORD_DIR)
  FileUtils.rm_rf("#{RECORD_DIR}_64")

  system('./ci_scripts/test.rb', '--only-snapshot-tests',
         '--scheme', 'AllStripeFrameworks',
         '--device', DEVICE_MODEL,
         '--version', os_version,
         exception: true)

  # FBSnapshotTestCase appends _64 for 64-bit architecture
  actual_record_dir = if Dir.exist?("#{RECORD_DIR}_64")
                       "#{RECORD_DIR}_64"
                     elsif Dir.exist?(RECORD_DIR)
                       RECORD_DIR
                     else
                       abort "Error: No snapshots recorded (expected #{RECORD_DIR} or #{RECORD_DIR}_64)"
                     end

  puts "==> Comparing against reference images (iOS #{os_version})..."

  Dir.glob("#{actual_record_dir}/**/*.png").each do |recorded_file|
    rel_path = recorded_file.sub("#{actual_record_dir}/", '')
    reference_file = File.join(REFERENCE_DIR, rel_path)

    # Copy to a persistent location (temp dir is cleared between versions)
    persistent_copy = File.join('/tmp/snapshot-all-recorded', rel_path)
    FileUtils.mkdir_p(File.dirname(persistent_copy))
    FileUtils.cp(recorded_file, persistent_copy)

    if !File.exist?(reference_file)
      added_files[rel_path] = persistent_copy
    elsif !FileUtils.compare_file(reference_file, recorded_file)
      if significant_difference?(reference_file, recorded_file)
        changed_files[rel_path] = persistent_copy
      end
    end
  end
end

if changed_files.empty? && added_files.empty?
  puts '==> No meaningful snapshot changes detected.'
  exit 0
end

puts "==> Found #{changed_files.size} modified, #{added_files.size} added"
(changed_files.keys + added_files.keys).each { |f| puts "  #{f}" }

# Step 3: Generate diff images (white background, red changed pixels)
DIFF_DIR = '/tmp/snapshot-diffs'
FileUtils.rm_rf(DIFF_DIR)
FileUtils.mkdir_p(DIFF_DIR)

changed_files.each do |rel_path, recorded_file|
  reference_file = File.join(REFERENCE_DIR, rel_path)
  diff_file = File.join(DIFF_DIR, rel_path)
  FileUtils.mkdir_p(File.dirname(diff_file))
  system('compare', '-fuzz', FUZZ,
         reference_file, recorded_file,
         '-highlight-color', 'Red', '-lowlight-color', 'White', '-compose', 'Src',
         diff_file, [:err] => '/dev/null')
end

deploy_dir = ENV['BITRISE_DEPLOY_DIR']
if deploy_dir && !changed_files.empty?
  zip_path = File.join(deploy_dir, 'snapshot-diffs.zip')
  system('zip', '-r', zip_path, DIFF_DIR, [:out] => '/dev/null')
  puts "==> Diff images zipped to #{zip_path}"
end

# Generate HTML report
html_report_dir = ENV['BITRISE_HTML_REPORT_DIR'] || '/tmp/snapshot-report'
if !changed_files.empty?
  require 'base64'
  report_dir = File.join(html_report_dir, 'snapshot-diffs')
  FileUtils.mkdir_p(report_dir)

  rows = changed_files.map do |rel_path, recorded_file|
    diff_file = File.join(DIFF_DIR, rel_path)
    old_file = File.join(REFERENCE_DIR, rel_path)
    name = File.basename(rel_path)

    diff_b64 = File.exist?(diff_file) ? Base64.strict_encode64(File.binread(diff_file)) : ''
    old_b64 = File.exist?(old_file) ? Base64.strict_encode64(File.binread(old_file)) : ''
    new_b64 = File.exist?(recorded_file) ? Base64.strict_encode64(File.binread(recorded_file)) : ''

    <<~ROW
      <div class="item">
        <h3>#{name}</h3>
        <div class="images">
          <div><p>Before</p><img src="data:image/png;base64,#{old_b64}"></div>
          <div><p>After</p><img src="data:image/png;base64,#{new_b64}"></div>
          <div><p>Diff</p><img src="data:image/png;base64,#{diff_b64}"></div>
        </div>
      </div>
    ROW
  end.join

  html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
    <style>
      body { font-family: -apple-system, sans-serif; background: #1a1a1a; color: #eee; padding: 20px; }
      h2 { margin-bottom: 16px; }
      .item { background: #2a2a2a; border-radius: 8px; padding: 16px; margin-bottom: 16px; }
      .item h3 { font-size: 14px; margin-bottom: 12px; word-break: break-all; }
      .images { display: flex; gap: 12px; flex-wrap: wrap; }
      .images > div { text-align: center; }
      .images p { font-size: 11px; color: #999; margin-bottom: 4px; }
      .images img { border: 1px solid #444; border-radius: 4px; image-rendering: pixelated; }
    </style>
    </head>
    <body>
    <h2>Snapshot Diffs — #{changed_files.size} changed</h2>
    #{rows}
    </body>
    </html>
  HTML

  report_path = File.join(report_dir, 'index.html')
  File.write(report_path, html)
  puts "==> HTML report: #{report_path}"

  # Open locally if not in CI
  system('open', report_path) unless ENV['CI'] || ENV['BITRISE_IO']
end

exit 0 if dry_run

# Step 4: Copy changed files to reference directory
(changed_files.merge(added_files)).each do |rel_path, recorded_file|
  dst = File.join(REFERENCE_DIR, rel_path)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(recorded_file, dst)
end

puts '==> Reference images updated.'

exit 0 unless commit

# Step 5: Commit
puts '==> Committing snapshot changes...'
(changed_files.keys + added_files.keys).each do |rel_path|
  system('git', 'add', File.join('Tests/ReferenceImages_64', rel_path))
end

message = "Update snapshot reference images\n\n#{changed_files.size} modified, #{added_files.size} added"
system('git', 'commit', '-m', message, exception: true)

puts '==> Done.'

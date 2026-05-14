#!/usr/bin/env ruby
# frozen_string_literal: true

# update_snapshots.rb
#
# Records snapshot tests, compares against the existing reference images using
# a pixel-difference threshold, and commits+pushes only meaningful changes.
#
# Usage:
#   ruby ci_scripts/update_snapshots.rb [--dry-run]
#
# Requires: ImageMagick (brew install imagemagick)

require 'fileutils'
require 'optparse'

SCRIPT_DIR = __dir__
ROOT_DIR = File.expand_path('..', SCRIPT_DIR)
Dir.chdir(ROOT_DIR)

RECORD_DIR = '/tmp/snapshot-records'
REFERENCE_DIR = File.join(ROOT_DIR, 'Tests/ReferenceImages_64')
DIFF_THRESHOLD = 0.1 # percentage of pixels that must differ
FUZZ = '5%' # per-pixel color tolerance before counting as different

dry_run = false
OptionParser.new do |opts|
  opts.banner = 'Usage: update_snapshots.rb [--dry-run]'
  opts.on('--dry-run', 'Show what would change without committing') { dry_run = true }
end.parse!

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

# Step 0: Skip if the last commit is already a snapshot update from CI.
# This prevents infinite loops when snapshots have minor flakiness that
# passes the threshold. Safe because CI rebases on the latest branch tip
# before pushing, so any human commits are already included in the recording.
last_commit_author = `git log -1 --format='%an'`.strip
last_commit_message = `git log -1 --format='%s'`.strip
if last_commit_author == 'Bitrise CI' && last_commit_message == 'Update snapshot reference images'
  puts '==> Last commit is a snapshot update — skipping to avoid loop.'
  exit 0
end

# Step 1: Record snapshots
puts '==> Recording snapshots...'
FileUtils.rm_rf(RECORD_DIR)
FileUtils.rm_rf("#{RECORD_DIR}_64")
system('ruby', 'ci_scripts/snapshots.rb', '--record', exception: true)

# FBSnapshotTestCase appends _64 for 64-bit architecture
actual_record_dir = if Dir.exist?("#{RECORD_DIR}_64")
                     "#{RECORD_DIR}_64"
                   elsif Dir.exist?(RECORD_DIR)
                     RECORD_DIR
                   else
                     abort "Error: No snapshots recorded (expected #{RECORD_DIR} or #{RECORD_DIR}_64)"
                   end

# Step 2: Compare and collect meaningful changes
puts '==> Comparing against reference images...'
changed_files = []
added_files = []

Dir.glob("#{actual_record_dir}/**/*.png").each do |recorded_file|
  rel_path = recorded_file.sub("#{actual_record_dir}/", '')
  reference_file = File.join(REFERENCE_DIR, rel_path)

  if !File.exist?(reference_file)
    added_files << rel_path
  elsif !FileUtils.compare_file(reference_file, recorded_file)
    if significant_difference?(reference_file, recorded_file)
      changed_files << rel_path
    end
  end
end

if changed_files.empty? && added_files.empty?
  puts '==> No meaningful snapshot changes detected.'
  exit 0
end

puts "==> Found #{changed_files.size} modified, #{added_files.size} added"

# Step 3: Generate diff images (white background, red changed pixels)
DIFF_DIR = '/tmp/snapshot-diffs'
FileUtils.rm_rf(DIFF_DIR)
FileUtils.mkdir_p(DIFF_DIR)

changed_files.each do |rel_path|
  reference_file = File.join(REFERENCE_DIR, rel_path)
  recorded_file = File.join(actual_record_dir, rel_path)
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

# Generate HTML report with inline base64 diff images
html_report_dir = ENV['BITRISE_HTML_REPORT_DIR']
if html_report_dir && !changed_files.empty?
  require 'base64'
  report_dir = File.join(html_report_dir, 'snapshot-diffs')
  FileUtils.mkdir_p(report_dir)

  rows = changed_files.map do |rel_path|
    diff_file = File.join(DIFF_DIR, rel_path)
    old_file = File.join(REFERENCE_DIR, rel_path)
    new_file = File.join(actual_record_dir, rel_path)
    name = File.basename(rel_path)

    diff_b64 = File.exist?(diff_file) ? Base64.strict_encode64(File.binread(diff_file)) : ''
    old_b64 = File.exist?(old_file) ? Base64.strict_encode64(File.binread(old_file)) : ''
    new_b64 = File.exist?(new_file) ? Base64.strict_encode64(File.binread(new_file)) : ''

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

  File.write(File.join(report_dir, 'index.html'), html)
  puts "==> HTML report saved to #{report_dir}"
end

# Step 4: Copy changed files to reference directory
(changed_files + added_files).each do |rel_path|
  src = File.join(actual_record_dir, rel_path)
  dst = File.join(REFERENCE_DIR, rel_path)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(src, dst)
end

if dry_run
  puts '==> Dry run — would commit these files:'
  (changed_files + added_files).each { |f| puts "  #{f}" }
  exit 0
end

# Step 4: Commit and push
puts '==> Committing snapshot changes...'
(changed_files + added_files).each do |rel_path|
  system('git', 'add', File.join('Tests/ReferenceImages_64', rel_path))
end

message = "Update snapshot reference images\n\n#{changed_files.size} modified, #{added_files.size} added"
system('git', 'commit', '-m', message, exception: true)

branch = ENV['BITRISE_GIT_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip
if branch == 'HEAD'
  abort 'Error: Could not determine branch name. Set BITRISE_GIT_BRANCH.'
end

puts "==> Pushing to #{branch}..."
system('git', 'remote', 'set-url', 'origin', 'git@github.com:stripe/stripe-ios.git')
system('git', 'fetch', 'origin', branch, [:out, :err] => '/dev/null')
system('git', 'rebase', "origin/#{branch}", exception: true)
system('git', 'push', 'origin', "HEAD:#{branch}", exception: true)

puts '==> Done.'

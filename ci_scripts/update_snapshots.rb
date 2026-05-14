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
  num_diff = `compare -metric AE -fuzz 5% '#{file_a}' '#{file_b}' /dev/null 2>&1`.strip.to_i
  total_pixels = `identify -format '%[fx:w*h]' '#{file_a}' 2>/dev/null`.strip.to_i
  return true if total_pixels == 0

  (num_diff.to_f / total_pixels * 100) > DIFF_THRESHOLD
end

require_imagemagick!

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

# Step 3: Copy changed files to reference directory
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

branch = `git rev-parse --abbrev-ref HEAD`.strip
puts "==> Pushing to #{branch}..."
system('git', 'push', 'origin', branch, exception: true)

puts '==> Done.'

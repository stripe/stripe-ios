#!/usr/bin/env ruby

require 'digest'
require 'json'
require 'open3'
require_relative '../ci_change_scope'

def capture!(*command)
  output, status = Open3.capture2(*command)
  abort("Command failed: #{command.first}") unless status.success?
  output
end

def ensure_commit!(revision)
  abort('Expected an immutable commit SHA') unless revision&.match?(/\A[0-9a-f]{40}\z/)
  return if system('git', 'cat-file', '-e', "#{revision}^{commit}", out: File::NULL, err: File::NULL)
  capture!('git', 'fetch', '--no-tags', '--depth=1', 'origin', revision)
end

event = JSON.parse(File.read(ENV.fetch('GITHUB_EVENT_PATH')))
head = capture!('git', 'rev-parse', 'HEAD').strip
abort('The checkout does not match the immutable event revision') unless head == ENV.fetch('GITHUB_SHA')
base = if ENV.fetch('GITHUB_EVENT_NAME') == 'pull_request'
         event.fetch('pull_request').fetch('base').fetch('sha')
       else
         event.fetch('before')
       end

if base == '0' * 40
  required = true
else
  ensure_commit!(base)
  if ENV.fetch('GITHUB_EVENT_NAME') == 'pull_request'
    abort('The checked-out PR merge must include the event base revision') unless system('git', 'merge-base', '--is-ancestor', base, head)
  end
  paths = capture!('git', 'diff', '--name-only', '--no-renames', '-z', base, head).split("\0")
  required = CIChangeScope.scan_required?(paths)
end

outputs = { 'head_sha' => head, 'base_sha' => base, 'required' => required.to_s }
if required
  toolchain = [
    capture!('xcodebuild', '-version'),
    capture!('xcrun', 'swiftc', '--version'),
    capture!('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-build-version')
  ]
  recipe_paths = Dir['ci_scripts/api_diff/*.rb'].sort + ['ci_scripts/ci_change_scope.rb', '.github/workflows/verify-public-interface.yml']
  fingerprint = Digest::SHA256.hexdigest((toolchain + recipe_paths.map { |path| File.read(path) }).join("\0"))
  outputs.merge!(
    'fingerprint' => fingerprint,
    'base_key' => "public-api-v1-#{fingerprint}-#{base}",
    'head_key' => "public-api-v1-#{fingerprint}-#{head}"
  )
end
File.open(ENV.fetch('GITHUB_OUTPUT'), 'a') { |file| outputs.each { |key, value| file.puts("#{key}=#{value}") } }
puts(required ? 'SDK or build inputs changed; compare public interfaces.' : 'Only tests, examples, or documentation changed; no framework archive needed.')

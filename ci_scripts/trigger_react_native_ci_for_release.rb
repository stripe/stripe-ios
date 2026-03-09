#!/usr/bin/env ruby

# This script triggers stripe-react-native CI builds when a stripe-ios release PR is created.
# It's called from the Bitrise releases-trigger-pipeline.

require_relative 'common'

# Get the current branch name and version
current_branch = ENV['BITRISE_GIT_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip
release_version = File.read('VERSION').strip
release_branch = current_branch

puts "=" * 60
puts "Stripe React Native CI Trigger"
puts "=" * 60
puts "Release branch: #{release_branch}"
puts "Release version: #{release_version}"
puts

# Check if we should test React Native
rn_version = get_stripe_react_native_stripe_ios_version
if rn_version.nil?
  puts "⚠ Could not fetch stripe-react-native version, skipping CI trigger"
  exit 0
end

puts "stripe-react-native is pinned to: #{rn_version}.x"

unless should_test_react_native?(release_version)
  puts "✗ Version mismatch - stripe-react-native (#{rn_version}.x) doesn't match release (#{release_version})"
  puts "  Skipping CI trigger"
  exit 0
end

puts "✓ Version match - triggering CI"
puts

# Trigger the build
api_token = ENV['BITRISE_ACCESS_TOKEN']
app_slug = 'cf3f9f9d-0fa5-484a-a09b-5649a1512f6b'

unless api_token
  puts "✗ BITRISE_ACCESS_TOKEN not set, cannot trigger CI"
  exit 1
end

puts "Triggering stripe-react-native CI..."

uri = URI("https://api.bitrise.io/v0.1/apps/#{app_slug}/builds")
request = Net::HTTP::Post.new(uri)
request['Authorization'] = api_token
request['Content-Type'] = 'application/json'
request.body = {
  build_params: {
    branch: 'master',
    pipeline_id: 'main-trigger-pipeline',
    commit_message: "Test stripe-ios release branch: #{release_branch}",
    environments: [
      {
        mapped_to: 'OVERRIDE_STRIPE_IOS_VERSION_GIT_BRANCH',
        value: release_branch,
        is_expand: false
      }
    ]
  },
  hook_info: { type: 'bitrise' }
}.to_json

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

if response.code == '201'
  result = JSON.parse(response.body)
  build_url = result['build_url']
  puts "✓ RN CI triggered successfully!"
  puts "  Build URL: #{build_url}"
  puts
  exit 0
else
  puts "✗ Failed to trigger RN CI"
  puts "  Status: #{response.code}"
  puts "  Response: #{response.body}"
  exit 1
end

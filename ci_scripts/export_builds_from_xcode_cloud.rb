#!/usr/bin/env ruby

require "httparty"
require "spaceship"

# This is the project ID for Stripe.framework in Xcode Cloud
STRIPE_FRAMEWORK_PRODUCT_ID = "F5D3978D-8EE7-4D91-B5F5-C73632939061"

# Git commit SHA for the current branch
build_commit = `git rev-parse HEAD`.strip

def die(string)
  abort("[#{File.basename(__FILE__)}] [ERROR] #{string}")
end

# Cribbed from the Dashboard app
class AppStoreConnectAPI
  include HTTParty
  base_uri "https://api.appstoreconnect.apple.com/v1"

  def initialize(token)
    @headers = {
      "Authorization" => "Bearer #{token}"
    }
  end

  def buildRuns(ci_product_id)
    self.class.get(
      "/ciProducts/#{ci_product_id}/buildRuns",
      {
        headers: @headers,
        query: {
          # Sort with most recent builds first
          "sort" => "-number"
        }
      }
    )
  end

  def actions(ci_buildrun_id)
    self.class.get(
      "/ciBuildRuns/#{ci_buildrun_id}/actions",
      {
        headers: @headers,
        query: {}
      }
    )
  end

  def artifacts(ci_buildaction_id)
    self.class.get(
      "/ciBuildActions/#{ci_buildaction_id}/artifacts",
      {
        headers: @headers,
        query: {}
      }
    )
  end
end

api_key = `fetch-password xcode-cloud-sdk-fetch-key`
# Convert JSON to hash, create App Store Connect API token
api_key = JSON.parse(api_key)
token = Spaceship::ConnectAPI::Token.from(hash: api_key)
client = AppStoreConnectAPI.new(token.text)

# Get the latest build runs for Stripe.framework
build_runs = client.buildRuns(STRIPE_FRAMEWORK_PRODUCT_ID)["data"]
die("No build runs found.") if build_runs.nil?
# Get build run where commitSha == 'commit_sha' and completionStatus == 'SUCCEEDED'
build_run = build_runs
  .filter { |build_run|
    build_run["attributes"]["sourceCommit"]["commitSha"] == build_commit &&
      build_run["attributes"]["completionStatus"] == "SUCCEEDED"
  }
  .first
die("Completed build run not found for commit #{build_commit}. Did CI finish running?") if build_run.nil?
actions = client.actions(build_run["id"])["data"]
die("No actions found for build.") if actions.nil?
# Get the action where attributes['name'] == 'Build - iOS' and completionStatus == 'SUCCEEDED'
build_action = actions.find { |action|
  action["attributes"]["name"] == "Build - iOS" && action["attributes"]["completionStatus"] == "SUCCEEDED"
}
die("Couldn't find build_action for 'Build - iOS' with status 'SUCCEEDED'. Did find: #{actions}") if build_action.nil?
artifacts = client.artifacts(build_action["id"])["data"]
die("No artifacts found for build action.") if artifacts.nil?
# Get the artifact where fileType == 'XCODEBUILD_PRODUCTS'
artifact = artifacts.filter { |artifact| artifact["attributes"]["fileType"] == "XCODEBUILD_PRODUCTS" }.first
die("No XCODEBUILD_PRODUCTS artifact found in artifacts: #{artifacts}") if artifact.nil?
# Download the artifact, which is a zip file containing the Stripe.xcframework.zip
# It'll be stored in something like 'Stripe Build 17 Build Products for ReleaseFrameworksTarget on iOS/Release-iphoneos/Stripe.xcframework.zip'
artifact_url = artifact["attributes"]["downloadUrl"]
puts("Fetching: #{artifact_url}")
`mkdir -p ./build/xcc_frameworks`
response = HTTParty.get(artifact_url)
File.open("build/Stripexcframework-build.zip", "wb") { |file| file.write(response.body) }
`unzip -o ./build/Stripexcframework-build.zip -d ./build/xcc_frameworks/`
# Find the Stripe.xcframework.zip (somewhere in the extracted files) and copy it to the root of the build directory
`find ./build/xcc_frameworks -name "Stripe.xcframework.zip" -exec cp {} ./build/ \\;`

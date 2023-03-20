#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'json'
require 'openssl'
require 'base64'

passed = true
if ARGV[0] == 'pass'
  passed = true
elsif ARGV[0] == 'fail'
  passed = false
else
  puts 'Usage: create_ticket.rb [pass] [fail]'
  exit 101
end

env_sdk_failure_notif_endpoint = ENV['SDK_FAILURE_NOTIFICATION_ENDPOINT']
env_sdk_failure_notif_endpoint_hmac_key = ENV['SDK_FAILURE_NOTIFICATION_ENDPOINT_HMAC_KEY']

if !env_sdk_failure_notif_endpoint || !env_sdk_failure_notif_endpoint_hmac_key
  puts "Two environment variables required: `SDK_FAILURE_NOTIFICATION_ENDPOINT` and `SDK_FAILURE_NOTIFICATION_ENDPOINT_HMAC_KEY`"
  puts "Visit http://go/ios-sdk-failure-notification-endpoint for details"
  exit 102
end

uri = URI(env_sdk_failure_notif_endpoint)
hmac_key = Base64.decode64(env_sdk_failure_notif_endpoint_hmac_key)

http = Net::HTTP.new(uri.host, uri.port).tap do |http|
  http.use_ssl = true
end
req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')

# Set up base params for tickets created under either
# success or failure cases
params = {
  project: "RUN_MOBILESDK",
}

if passed
  params[:summary] = "iOS end-to-end test passed."
  params[:description] = "No action needed. #{ENV['CIRCLE_BUILD_URL']}"
else
  params[:summary] = "iOS end-to-end test failed."
  params[:description] = "Please ack this ticket, investigate within 1 business day, and resolve within 5 business days. #{ENV['CIRCLE_BUILD_URL']}"
  params[:labels] = ENV['SDK_FAILURE_NOTIFICATION_LABELS'].split(',')
end

req.body = params.to_json

# Auth
digest = OpenSSL::Digest.new('sha256')
header_data = OpenSSL::HMAC.digest(digest, hmac_key, req.body)
header_data_64 = Base64.strict_encode64(header_data)
req.add_field 'X-TM-Signature', header_data_64

res = http.request(req)

# If the CI job passed, send a follow-up request to auto-close the ticket
if passed
  issueid = JSON.parse(res.body)['issueid']
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = {
    issueid: issueid,
    resolved: true
  }.to_json

  digest = OpenSSL::Digest.new('sha256')
  header_data = OpenSSL::HMAC.digest(digest, hmac_key, req.body)
  header_data_64 = Base64.strict_encode64(header_data)
  req.add_field 'X-TM-Signature', header_data_64

  res = http.request(req)
end

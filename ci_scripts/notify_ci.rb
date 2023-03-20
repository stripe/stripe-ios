#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'json'
require 'openssl'
require 'base64'

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

params = {
  project: "RUN_MOBILESDK",
  summary: "Job failed: #{ENV['CIRCLE_JOB']}",
  description: "Please investigate the failure: #{ENV['CIRCLE_BUILD_URL']}"
}

req.body = params.to_json

# Auth
digest = OpenSSL::Digest.new('sha256')
header_data = OpenSSL::HMAC.digest(digest, hmac_key, req.body)
header_data_64 = Base64.strict_encode64(header_data)
req.add_field 'X-TM-Signature', header_data_64

http.request(req)

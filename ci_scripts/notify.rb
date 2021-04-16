#!/usr/bin/env ruby
require 'uri'
require 'net/http'
require 'json'

passed = true
if ARGV[0] == 'pass'
  passed = true
elsif ARGV[0] == 'fail'
  passed = false
else
  puts 'Usage: notify.rb [pass] [fail]'
  exit
end

uri = URI(ENV['SDK_FAILURE_NOTIFICATION_ENDPOINT'])
http = Net::HTTP.new(uri.host, uri.port).tap do |http|
  http.use_ssl = true
end
req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')

params = { project: 'RUN_MOBILESDK' }
if passed
  params[:summary] = 'E2E test passed'
  params[:description] = "No action needed. #{ENV['CIRCLE_BUILD_URL']}"
else
  params[:summary] = 'E2E test failed'
  params[:description] = "Please ACK this ticket and investigate the failure. #{ENV['CIRCLE_BUILD_URL']}"
end

# Create ticket, store ID
req.body = params.to_json
res = http.request(req)

if passed
  # Resolve ticket
  issueid = JSON.parse(res.body)['issueid']
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = {
    issueid: issueid,
    resolved: true
  }.to_json
  http.request(req)
end

#!/usr/bin/env ruby

require_relative 'release_common'

last_release = get_current_release_version_of_repo('stripe/stripe-ios')

version = version_from_file

changelog = changelog(version)

# Print the latest commit hash
last_commit = `git log --pretty=format:'%h (%cd)' --date=format:'%Y-%m-%d' -n 1`
# Print the first commit hash from the last release
first_commit = `git log --pretty=format:'%h (%cd)' --date=format:'%Y-%m-%d' -n 1 #{last_release}`

# File a JIRA ticket under CHANGEDOC with the following fields:
jiradescription = %{
h3. Summary of the change

{code}
#{changelog}
{code}

h3. Commit range the change includes
First commit: #{first_commit}
Last commit: #{last_commit}

h3. Detailed rollout instructions
https://confluence.corp.stripe.com/display/MOBILE/iOS+SDK+Deploy+Guide

h3. Additional testing details
<Add any additional testing details or leave "n/a">
}

currentUser = ENV['USER']
jira_url = "https://jira.corp.stripe.com/secure/CreateIssueDetails!init.jspa?pid=10712&issuetype=10100&reporter=#{ERB::Util.url_encode(currentUser)}&summary=iOS+SDK+Release+#{ERB::Util.url_encode(version)}&description=#{ERB::Util.url_encode(jiradescription)}&components=iOS+SDK"

rputs "File a JIRA ticket..."
puts "You can file one manually at https://go/changedoc with the following information:"
puts "Summary: iOS SDK Release #{version}"
puts "Component: iOS SDK"
puts jiradescription
puts ""
prompt_user "Or press enter to open pre-filled ticket.\nClick 'Request Review' when you're done."
open_url jira_url
notify_user

rputs "Send an email to mobile-sdk-updates@stripe.com with the following information:"
puts "Subject: [iOS SDK] #{version}"
puts "Body:"
puts "#{changelog}"
puts ""
prompt_user "Press enter to open pre-filled email in your default client...\n(To make Gmail your default email client, visit https://support.google.com/a/users/answer/9308783)"
open_url "mailto:mobile-sdk-updates@stripe.com?subject=%5BiOS%20SDK%5D%20#{ERB::Util.url_encode(version)}&body=#{ERB::Util.url_encode(changelog)}"
notify_user

rputs "Release proposed. Please contact your reviewer."

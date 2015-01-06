#!/usr/bin/env ruby

git_version = `git describe`.strip.split("-").first
file_version = File.open('VERSION').first.strip
if (git_version != file_version)
end
search_result = `git grep #{git_version} Stripe/STPAPIClient.h`


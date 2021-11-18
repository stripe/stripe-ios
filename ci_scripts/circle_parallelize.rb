#!/usr/bin/env ruby

builds = []

# Shuffle the list of builds using a shared seed.
# This helps avoid a situation where one builder always handles the high-duration builds.
# It'd be better if we could evenly distribute these by duration instead.
shuffled_args = ARGV.shuffle(random: Random.new(ENV['CIRCLE_BUILD_NUM'].to_i))

i = 0
shuffled_args.each do |arg|
  if i % ENV['CIRCLE_NODE_TOTAL'].to_i == ENV['CIRCLE_NODE_INDEX'].to_i
    builds.append(arg)
  end
  i += 1
end

puts "I am CircleCI node #{ENV['CIRCLE_NODE_INDEX']}. #{ENV['CIRCLE_NODE_INDEX'].to_i + 1} of #{ENV['CIRCLE_NODE_TOTAL']} builders."
puts "I will run: #{builds.join(' ')}"

builds.each do |build|
  puts "Running fastlane test: #{build}"
  system("bundle exec fastlane #{build}")
  unless $?.success?
    puts "Build failed: #{build}"
    exit $?.exitstatus
  end
end

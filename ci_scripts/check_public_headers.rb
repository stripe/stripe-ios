#!/usr/bin/env ruby

begin
  gem "xcodeproj"
rescue LoadError
  system("gem install xcodeproj")
  Gem.clear_paths
end

require 'xcodeproj'

puts "Checking headers..."

contents_of_stripe_dot_h = (File.readlines("Stripe/PublicHeaders/Stripe.h").map do |line|
	/\#import \"(.*?)\"\n/.match(line)
end.compact.map do |match|
	match.captures.first
end + ["Stripe.h"]).sort
contents_of_public_headers_dir = Dir.glob("Stripe/PublicHeaders/*.h").map { |h| File.basename(h) }.sort

if contents_of_public_headers_dir != contents_of_stripe_dot_h
	likely_culprits = ([contents_of_stripe_dot_h - contents_of_public_headers_dir] + [contents_of_public_headers_dir - contents_of_stripe_dot_h]).uniq
	abort("The contents of Stripe/PublicHeaders do not match what is #imported in Stripe/PublicHeaders/Stripe.h. Likely culprits: #{likely_culprits}.")
end

dynamic_framework_target = Xcodeproj::Project.open('Stripe.xcodeproj').targets.select { |t| t.name == 'StripeiOS' }.first
dynamic_framework_public_headers = dynamic_framework_target.headers_build_phase.files.select do |f|
	f.settings && f.settings["ATTRIBUTES"] == ["Public"]
end.map(&:display_name).sort

if contents_of_public_headers_dir != dynamic_framework_public_headers
	likely_culprits = ([dynamic_framework_public_headers - contents_of_public_headers_dir] + [contents_of_public_headers_dir - dynamic_framework_public_headers]).uniq
	abort("The contents of Stripe/PublicHeaders do not match the public headers of the StripeiOS target. Likely culprits: #{likely_culprits}.")
end

static_library_target = Xcodeproj::Project.open('Stripe.xcodeproj').targets.select { |t| t.name == 'StripeiOSStatic' }.first
static_library_public_headers = static_library_target.headers_build_phase.files.select do |f|
	f.settings && f.settings["ATTRIBUTES"] == ["Public"]
end.map(&:display_name).sort

if contents_of_public_headers_dir != static_library_public_headers
	likely_culprits = ([static_library_public_headers - contents_of_public_headers_dir] + [contents_of_public_headers_dir - static_library_public_headers]).uniq
	abort("The contents of Stripe/PublicHeaders do not match the public headers of the StripeiOSStatic target. Likely culprits: #{likely_culprits}.")
end

puts "Headers look good!"

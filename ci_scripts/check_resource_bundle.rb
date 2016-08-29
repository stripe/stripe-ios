#!/usr/bin/env ruby

begin
  gem "xcodeproj"
rescue LoadError
  system("gem install xcodeproj")
  Gem.clear_paths
end

require 'xcodeproj'

contents_of_resources_dir = Dir.glob("Stripe/Resources/Images/*.png").map { |h| File.basename(h) }.uniq.sort
resource_bundle_target = Xcodeproj::Project.open('Stripe.xcodeproj').targets.select { |t| t.name == 'StripeiOSResources' }.first
resources = resource_bundle_target.resources_build_phase.file_display_names.uniq.sort.select{ |n| !n.end_with? ".strings"}

if contents_of_resources_dir != resources
  likely_culprits = ((contents_of_resources_dir - resources) + (resources - contents_of_resources_dir)).uniq
  abort("The contents of Stripe/Resources/Images do not match the contents of the StripeiOSResources target. Likely culprits: #{likely_culprits}.")
end

puts "Resource bundle looks good!"

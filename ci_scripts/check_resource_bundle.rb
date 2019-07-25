#!/usr/bin/env ruby

begin
  gem "xcodeproj"
rescue LoadError
  system("gem install xcodeproj")
  Gem.clear_paths
end

require 'xcodeproj'

contents_of_resources_dir = Dir.glob("Stripe/Resources/Images/*.png").map { |h| File.basename(h) }.uniq.sort
puts contents_of_resources_dir
targets = ['StripeiOSResources', 'StripeiOS']
targets.each do |target|

  resource_bundle_target = Xcodeproj::Project.open('Stripe.xcodeproj').targets.select { |t| t.name == target }.first
  resource_bundle_files = resource_bundle_target.resources_build_phase.file_display_names
  duplicates = resource_bundle_files.select { |f| resource_bundle_files.count(f) > 1 }.uniq
  if duplicates.any?
    abort("Found some duplicate entries in the resources build phase for target #{target}:\n#{duplicates}")
  end
  resources = resource_bundle_files.uniq.sort.select{ |n| !(n.end_with?(".strings") || n.end_with?(".sh") || n == "Stripe3DS2.bundle") }
  puts resources

  if contents_of_resources_dir != resources
    likely_culprits = ((contents_of_resources_dir - resources) + (resources - contents_of_resources_dir)).uniq
    abort("The contents of Stripe/Resources/Images do not match the contents of the #{target} target. Likely culprits: #{likely_culprits}.")
  end

end

puts "Resources look good!"

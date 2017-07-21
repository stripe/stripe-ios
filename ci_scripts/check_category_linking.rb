#!/usr/bin/env ruby
# This script checks that all categories are referenced in STPCategoryLoader,
# which ensures they get linked in the static framework.

begin
  gem "xcodeproj"
rescue LoadError
  system("gem install xcodeproj")
  Gem.clear_paths
end

require 'xcodeproj'

puts "Checking category linking..."

loaded_categories = (File.readlines("Stripe/STPCategoryLoader.m").map do |line|
  /\#import \"(.*?)\"\n/.match(line)
end.compact.map do |match|
  match.captures.first
end).sort

all_headers = (Dir.glob("Stripe/PublicHeaders/*.h") + Dir.glob("Stripe/*.h")).map do |h|
  filename = File.basename(h)
end

def is_category(h)
  if h.include?("+")
    return !h.include?("Private") && !h.include?("Fabric")
  else
    other_categories = ["StripeError.h", "STPAspects.h"]
    return other_categories.include?(h)
  end
end

categories = (all_headers.select {|h| is_category(h) }).sort

missing_categories = categories - loaded_categories
if missing_categories.count > 0
  abort("Found categories not linked in STPCategoryLoader:\n#{missing_categories}")
end

puts "Category linking looks good!"

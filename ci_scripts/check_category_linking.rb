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

def needs_category_loading(file)
  implementations = File.readlines(file).select {|l| /\@implementation/.match(l)}
  class_implementations = implementations.select {|l| !(/\(.*\)/.match(l)) }
  category_implementations = implementations.select {|l| /\(.*\)/.match(l) }
  category_implementations.count > 0 && class_implementations.count == 0
end

all_mfiles = Dir.glob("Stripe/*.m")
categories = all_mfiles.select do |file|
  needs_category_loading(file)
end.map do |file|
  File.basename(file).gsub(".m", ".h")
end.sort

missing_categories = categories - loaded_categories

if missing_categories.count > 0
  abort("Found categories not linked in STPCategoryLoader:\n#{missing_categories}")
end

puts "Category linking looks good!"

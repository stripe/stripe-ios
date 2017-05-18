#!/usr/bin/env ruby
# encoding: utf-8

# This script adds card.io to the swift example app.

begin
  gem "xcodeproj"
rescue LoadError
  system("gem install xcodeproj")
  Gem.clear_paths
end

require 'xcodeproj'

puts '▸ Installing card.io – this may take a while'
system('cd Example; carthage update')

project_path = 'Example/Stripe iOS Example (Simple).xcodeproj'
project = Xcodeproj::Project.open(project_path)

# add framework
lib_path = 'Carthage/Build/iOS/CardIO.framework'
libRef = project['Frameworks'].new_file(lib_path);
framework_buildphase = project.objects.select{|x| x.class == Xcodeproj::Project::Object::PBXFrameworksBuildPhase}[0];

# update framework search paths
framework_buildphase.add_file_reference(libRef);
target = project.targets.first
['Debug', 'Release'].each do |config|
  paths = ["$(inherited)", "$(PROJECT_DIR)", "$(PROJECT_DIR)/Carthage/Build/iOS"]
  target.build_settings(config)['FRAMEWORK_SEARCH_PATHS'] = paths
end

# add carthage build phase
carthage_buildphase = target.new_shell_script_build_phase("Carthage")
carthage_buildphase.shell_script = '/usr/local/bin/carthage copy-frameworks'
carthage_buildphase.input_paths = ['$(SRCROOT)/Carthage/Build/iOS/CardIO.framework']

project.save();

puts '▸ Updated Stripe iOS Example (Simple) to use card.io.'
puts "▸ If you run the example app on a device, you'll see a 'Scan Card' option when adding a new card."

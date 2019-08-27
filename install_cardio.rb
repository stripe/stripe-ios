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
open('Example/Cartfile', 'a') { |f|
  f.puts "github \"card-io/card.io-iOS-source\""
}
system('cd Example; carthage update --platform ios')

project_name = 'Standard Integration'
project_path = "Example/#{project_name}.xcodeproj"
project = Xcodeproj::Project.open(project_path)

# add framework
lib_path = 'Carthage/Build/iOS/CardIO.framework'
libRef = project['Frameworks'].new_file(lib_path);
framework_buildphase = project.objects.select {
  |x| x.class == Xcodeproj::Project::Object::PBXFrameworksBuildPhase
}[0];
framework_buildphase.add_file_reference(libRef);

# update carthage build phase
carthage_buildphase = project.objects.select {
  |x| x.class == Xcodeproj::Project::Object::PBXShellScriptBuildPhase && x.name == "Carthage Copy Frameworks"
}[0];
carthage_buildphase.input_paths = [
  '$(SRCROOT)/Carthage/Build/iOS/CardIO.framework',
]

project.save();

puts "▸ Updated #{project_name} to use card.io."
puts "▸ If you run the example app on a device, you'll see a 'Scan Card' option when adding a new card."

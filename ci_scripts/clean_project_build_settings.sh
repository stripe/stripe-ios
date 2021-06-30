#!/bin/bash
#
# Finds all of the build settings configured in .xcconfig files and deletes them
# from the specified project file. This ensures that the build settings from the
# xcconfig files are not getting overwritten.
#

project_file=$1

if [[ $project_file != *project.pbxproj ]]
then
    echo "Specify the path to a 'project.pbxproj' file"
    exit 1
fi

build_settings=()
IFS=$'\n'

# Get all the build settings from all the .xcconfig files in `BuildConfigurations`
for file in BuildConfigurations/*.xcconfig
do
  # Extract the list build settings
  output="$(grep -e "^\w\w*\s*=" "$file" | sed -E "s|([A-Za-z_]+) *=.*|\1|")"

  # Split into an array and concatenate
  array=($output)
  build_settings+=("${array[@]}")
done

# Find buld settings in project.pbxproj file and remove
for ((i=0; i<${#build_settings[@]}; i++))
do
  build_setting=${build_settings[$i]}

  # Removes setting from project file
  cat ${project_file} | sed -E "/^[[:space:]]*${build_setting}[[:space:]]*=[[:space:]]*.+;$/d" > ${project_file}.copy
  mv ${project_file}.copy ${project_file}

  echo "Removing ${build_setting}"
done

echo Done!

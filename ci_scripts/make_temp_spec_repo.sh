#!/bin/bash

# This script is used from `build_documentation.sh` as a workaround for a jazzy
# limitation so we can specify pod dependencies using the local source directory.
# It creates a temp git repo mimicing the directory structure of a pod spec
# repo containing modified versions of our *.podspec files which use a local
# file:// URL as their source. It prints the resulting directory path which is
# passed to jazzy as its `--pod-sources` argument.
#
# Note: The temporary directory should be deleted after it's finished being used.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(realpath "${script_dir}/../")"

release_version="$(cat "${root_dir}/VERSION")"

# Create temp podspec directory
temp_spec_dir="$(mktemp -d)"

# Copy and modify each podspec
for podspec in ${root_dir}/*.podspec
do
  # Extract the name of the pod
  filename="$(basename $podspec)"
  podname="${filename%.*}"

  # Create expected directory structure for .podspec file
  mkdir "$temp_spec_dir/$podname"
  mkdir "$temp_spec_dir/$podname/$release_version"

  # Replace the s.source with file:// URL pointing to root_dir
  cat $podspec \
    | sed -E "s|(s\.source *= *)\{(.*)\}|\1\{ :git => 'file://$root_dir' \}|" \
    > "$temp_spec_dir/$podname/$release_version/$filename"
done

# Cocoapods needs this directory to be a git repo so it can clone it
cd "$temp_spec_dir"
git init -q > /dev/null
git add . > /dev/null
git commit -m "initial commit" > /dev/null

# print dir path when we're done
echo $temp_spec_dir

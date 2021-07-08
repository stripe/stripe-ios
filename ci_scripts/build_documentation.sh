#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Verify jazzy is installed
if ! command -v jazzy > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    die "Please install jazzy: https://github.com/realm/jazzy#installation"
  fi

  info "Installing jazzy..."
  gem install jazzy --no-document || die "Executing \`gem install jazzy\` failed"
fi

# Verify jazzy is up to date
jazzy_version_local="$(jazzy --version | grep --only-matching --extended-regexp "[0-9\.]+")"
jazzy_version_remote="$(gem search ^jazzy$ --remote --no-verbose | grep --only-matching --extended-regexp "[0-9\.]+")"

if [[ "${jazzy_version_local}" != "${jazzy_version_remote}" ]]; then
  die "Please update jazzy: \`gem update jazzy\`"
fi

# Create temp podspec directory
# NOTE(mludowise): This won't be needed if jazzy ever allows for multiple development pods
temp_spec_dir="$(/bin/bash "$script_dir/make_temp_spec_repo.sh")"
make_dir_status=$?

if [ $make_dir_status -ne 0 ]; then
  die "$temp_spec_dir"
fi
echo "Sucessfully created podspec repo at \`$temp_spec_dir\`"

# Clean pod cache to always use latest local copy of pod dependencies
# NOTE(mludowise): This won't be needed if jazzy ever allows for multiple development pods
for podspec in ${script_dir}/../*.podspec
do
  # Extract the name of the pod
  filename="$(basename $podspec)"
  podname="${filename%.*}"

  pod cache clean $podname --all
done

# Execute jazzy
release_version="$(cat "${script_dir}/../VERSION")"

info "Executing jazzy..."
jazzy \
  --config "${script_dir}/../.jazzy.yaml" \
  --github-file-prefix "https://github.com/stripe/stripe-ios/tree/${release_version}" \
  --podspec Stripe.podspec \
  --pod-sources "file://$temp_spec_dir"

# Cleanup temp podspec directory
rm -rf "$temp_spec_dir"

# Verify jazzy exit code
jazzy_exit_code="$?"

if [[ "${jazzy_exit_code}" != 0 ]]; then
  die "Executing jazzy failed with status code: ${jazzy_exit_code}"
fi

info "All good!"

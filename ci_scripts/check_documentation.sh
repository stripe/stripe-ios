#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_file="${TMPDIR}/jazzy_status.log"

if ! command -v jazzy > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    echo "ERROR: Please install jazzy:"
    echo "https://github.com/realm/jazzy"
    exit 1
  fi

  echo "Installing jazzy..."

  gem install jazzy || die "Executing \`gem install jazzy\` failed"

fi

echo "Log is going to ${log_file}"

# Reset log file
echo "Resetting log file..."
rm -f "${log_file}"

echo "Executing jazzy..."
jazzy \
  --no-clean \
  --output "${script_dir}/../docs/docs" \
  --skip-documentation \
  --framework-root "${script_dir}/.." \
  --umbrella-header "${script_dir}/../Stripe/PublicHeaders/Stripe.h" \
  --objc \
  --sdk iphonesimulator \
  > ${log_file}

# Verify jazzy exit code
jazzy_exit_code="$?"

if [[ "${jazzy_exit_code}" != 0 ]]; then
  echo "ERROR: Executing jazzy failed with status code: ${jazzy_exit_code}"
  exit 1
fi

# Search for coverage in log file
echo "Searching for coverage status..."
grep "100% documentation coverage" "${log_file}" > "/dev/null"

if [[ "$?" != 0 ]]; then
  echo "ERROR: Less than 100% documentation coverage!"
  echo "See docs/docs/undocumented.json"
  exit 1
fi

echo "All good!"

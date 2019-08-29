#!/bin/bash

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_file="${TMPDIR}/jazzy_status.log"

if ! command -v jazzy > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    die "ERROR: Please install jazzy: https://github.com/realm/jazzy"
  fi

  info "Installing jazzy..."

  gem install jazzy || die "Executing \`gem install jazzy\` failed"

fi

info "Log is going to ${log_file}"

# Reset log file
info "Resetting log file..."
rm -f "${log_file}"

info "Executing jazzy..."
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
  die "Executing jazzy failed with status code: ${jazzy_exit_code}"
fi

# Search for coverage in log file
info "Searching for coverage status..."
grep "100% documentation coverage" "${log_file}" > "/dev/null"

if [[ "$?" != 0 ]]; then
  cat docs/docs/undocumented.json; echo
  die "Less than 100% documentation coverage! See docs/docs/undocumented.json"
fi

info "All good!"

#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${CI}" == "true" && "${TRAVIS_SECURE_ENV_VARS}" != "true" ]]; then
  echo "WARNING: Skipping fauxpas linting for forked repository"
  exit 0
fi

# Assign Xcode developer tools path
# http://fauxpasapp.com/docs/#i-have-multiple-versions-of-xcode-installed-how-do-i-ensure-faux-pas-uses-the-one-i-want-it-to-use
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

# Install fauxpas if needed
if ! command -v fauxpas > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    echo "ERROR: Please install the Faux Pas app and the fauxpas cli tool:"
    echo "http://fauxpasapp.com/docs/#using-the-command-line-interface"
    exit 1
  fi

  if [[ -z "${FAUX_PAS_LICENSE}" ]]; then
    echo "ERROR: FAUX_PAS_LICENSE environment variable is missing. Add it to .travis.yaml, after encrypting it:"
    echo
    echo "travis encrypt FAUX_PAS_LICENSE=..."
    echo "https://docs.travis-ci.com/user/environment-variables/#encrypting-environment-variables"
    echo
    echo "Any of our organizational seat licenses can be used: http://fauxpasapp.com/faq/#how-does-licensing-work-for-continuous-integration-ci-servers"
    exit 10
  else
    echo "Found FAUX_PAS_LICENSE environment variable"
  fi

  echo "Installing fauxpas CLI..."
  /Applications/FauxPas.app/Contents/Resources/install-cli-tools
  if [[ "$?" != 0 ]]; then
    echo "ERROR: Executing install-cli-tools exited with a non-zero status code"
    exit 1
  fi

  fauxpas updatelicense "organization-seat" "Stripe" "${FAUX_PAS_LICENSE}"
  if [[ "$?" != 0 ]]; then
    echo "ERROR: Executing updatelicense exited with a non-zero status code"
    exit 1
  fi
fi

# Execute fauxpas
echo "Linting with fauxpas..."

xcodeproj_path="${script_dir}/../Stripe.xcodeproj/"
config_path="${script_dir}/../FauxPasConfig/main.fauxpas.json"
min_severity="Concern"

set -ex

fauxpas check "${xcodeproj_path}" \
  --target "StripeiOS" \
  --configFile "${config_path}" \
  --minErrorStatusSeverity "${min_severity}"

set +ex

echo "All good!"

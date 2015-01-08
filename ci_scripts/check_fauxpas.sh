#!/bin/sh

if [[ $CI && "$TRAVIS_SECURE_ENV_VARS" != "true" ]]; then
  echo "Skipping Faux Pas linting."
  exit 0
fi

echo "Linting with Faux Pas..."
fauxpas check "./Tests/Stripe Tests.xcodeproj" --scheme "iOS Tests" --configFile "./ci_scripts/FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern && fauxpas check "./Tests/Stripe Tests.xcodeproj" --scheme "OSX Tests" --configFile "./ci_scripts/FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern

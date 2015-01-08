#!/bin/sh

if [[ "$TRAVIS_SECURE_ENV_VARS" != "true" ]]; then
  echo "Skipping Faux Pas linting."
  exit 0
fi

echo "Linting with Faux Pas..."
fauxpas check "../Stripe Tests/Stripe Tests.xcodeproj" --scheme "iOS Tests" --configFile "./FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern && fauxpas check "../Stripe Tests/Stripe Tests.xcodeproj" --scheme "OSX Tests" --configFile "./FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern

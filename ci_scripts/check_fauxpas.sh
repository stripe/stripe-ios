#!/bin/sh

if [[ $CI && "$TRAVIS_SECURE_ENV_VARS" != "true" ]]; then
  echo "Skipping Faux Pas linting."
  exit 0
fi

echo "Linting with Faux Pas..."
fauxpas check Stripe.xcodeproj/ --target "StripeiOSStatic" --configFile "./FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern

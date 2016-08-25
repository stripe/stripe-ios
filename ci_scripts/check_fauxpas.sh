#!/bin/sh

if [[ $CI && "$TRAVIS_SECURE_ENV_VARS" != "true" ]]; then
  echo "Skipping Faux Pas linting."
  exit 0
fi

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

if which fauxpas ; then
    echo "FausPas already installed; skipping installation"
else
	echo "Installing FauxPas..."
	brew cask install fauxpas

	/Applications/FauxPas.app/Contents/Resources/install-cli-tools
	fauxpas updatelicense "organization-seat" "Stripe, Inc" $FAUX_PAS_LICENSE
fi

echo "Linting with Faux Pas..."

set -e
fauxpas check Stripe.xcodeproj/ --target "StripeiOSStatic" --configFile "./FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern
fauxpas check Stripe.xcodeproj/ --target "StripeiOS" --configFile "./FauxPasConfig/main.fauxpas.json" --minErrorStatusSeverity Concern

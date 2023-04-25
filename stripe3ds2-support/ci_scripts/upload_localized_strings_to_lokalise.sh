#!/bin/bash

if [[ -z $(which lokalise2) ]]; then
    echo "Installing lokalise2 via homebrew..."
    brew tap lokalise/cli-2
    brew install lokalise2
fi

sh ci_scripts/check_for_new_localized_strings.sh
if [[ $? -ne 0 ]]; then
    echo "check_for_new_localized_strings.sh detected strings not added to Localizable.strings. Commit any new strings to Localizable.strings then re-run this script"
    exit 1
fi

API_TOKEN=$(fetch-password lokalise-api-token-manual -q)
# iOS 3DS2 SDK
PROJECT_ID=614720955e51bbfda93be1.46626639

lokalise2 --token $API_TOKEN \
          --project-id $PROJECT_ID \
          file upload \
          --file Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings \
          --lang-iso "en"

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

API_TOKEN=$(fetch-password mobile/lokalise/token -q)
PROJECT_ID=$(fetch-password mobile/lokalise/ios -q)

lokalise2 --token $API_TOKEN \
          --project-id $PROJECT_ID \
          file upload \
          --file Stripe/Resources/Localizations/en.lproj/Localizable.strings \
          --lang-iso "en"

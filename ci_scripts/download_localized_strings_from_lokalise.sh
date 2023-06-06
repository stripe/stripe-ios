#!/bin/bash

set -e

if [[ -z $(which lokalise2) ]]; then
    echo "Installing lokalise2 via homebrew..."
    brew tap lokalise/cli-2
    brew install lokalise2
fi

if [[ -z $(which recode) ]]; then
    echo "Installing recode via homebrew..."
    brew install recode
fi

API_TOKEN=$(fetch-password lokalise-api-token-manual -q)
# Android-iOS-SDK
PROJECT_ID=747824695e51bc2f4aa912.89576472

# Load LOCALIZATION_DIRECTORIES & LANGUAGES variables
source ci_scripts/localization_vars.sh

# This is the custom status ID for our project with which the localizers mark completed translations
FINAL_STATUS_ID=587

lokalise2 --token $API_TOKEN \
          --project-id $PROJECT_ID \
          file download \
          --format strings \
          --filter-langs $LANGUAGES \
          --custom-translation-status-ids $FINAL_STATUS_ID \
          --export-sort "a_z" \
          --directory-prefix . \
          --original-filenames=true

# Lint downloaded files.
./ci_scripts/l10n/lint.rb

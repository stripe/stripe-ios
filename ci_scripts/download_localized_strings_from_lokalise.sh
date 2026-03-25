#!/bin/bash

set -e

REQUIRED_VERSION="3.1.4"

if [[ -z $(which lokalise2) ]]; then
    echo "Installing lokalise2 v${REQUIRED_VERSION} via homebrew..."
    brew tap lokalise/cli-2
    brew install lokalise2
else
    CURRENT_VERSION=$(lokalise2 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
        echo "lokalise2 v${CURRENT_VERSION} is installed, but v${REQUIRED_VERSION} or newer is required. Upgrading..."
        brew upgrade lokalise2
    fi
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

lokalise2 --token "$API_TOKEN" \
          --project-id $PROJECT_ID \
          file download \
          --async \
          --format strings \
          --filter-langs "$LANGUAGES" \
          --filter-filenames "$LOKALISE_FILENAMES" \
          --custom-translation-status-ids $FINAL_STATUS_ID \
          --export-sort "a_z" \
          --directory-prefix . \
          --original-filenames=true

# Lint downloaded files.
./ci_scripts/l10n/lint.rb

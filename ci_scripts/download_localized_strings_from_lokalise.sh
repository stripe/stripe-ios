#!/bin/bash

if [[ -z $(which lokalise2) ]]; then
    echo "Installing lokalise2 via homebrew..."
    brew tap lokalise/cli-2
    brew install lokalise2
fi

if [[ -z $(which recode) ]]; then
    echo "Installing recode via homebrew..."
    brew install recode
fi

API_TOKEN=$(fetch-password mobile/lokalise/token -q)
PROJECT_ID=$(fetch-password mobile/lokalise/ios -q)

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

for DIRECTORY in ${LOCALIZATION_DIRECTORIES[@]}
do
  for f in ${DIRECTORY}/Resources/Localizations/*.lproj/*.strings
  do

    # Don't modify the en.lproj strings file or it could get out of sync with
    # genstrings and our linters won't pass
    if [[ "$(basename "$(dirname "$f")")" == "en.lproj" ]]
    then
      continue
    fi

    # lokalise doesn't consistently add lines in between keys, but genstrings does
    # so here we add an empty line every two lines (first line is comment, second is key=val)
    TMP_FILE=$(mktemp /tmp/download_localized_strings_from_lokalise.XXXXXX)

    awk 'BEGIN {last_empty = 0; last_content = 0; row = 0;}; {if (NR == last_empty + 3 && NF > 1) {print ""; last_empty = NR - 1} else if (NF <= 1) {last_empty = NR}}; {if (NF > 1) {last_content = NR}}; {row = row + 1}; 1; END {if (row == last_content) {print ""}}' $f > $TMP_FILE && mv $TMP_FILE $f
  done
done

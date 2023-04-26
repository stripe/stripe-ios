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

API_TOKEN=$(fetch-password lokalise-api-token-manual -q)
# iOS 3DS2 SDK
PROJECT_ID=614720955e51bbfda93be1.46626639
LANGUAGES="da,de,en-GB,en,es-419,es,fi,fr-CA,fr,hu,it,ja,ko,nb,nl,nn-NO,mt,pt-BR,pt-PT,ru,sv,tr,zh-HANS,zh-HK,zh-Hant"
# This is the custom status ID for our project with which the localizers mark completed translations
FINAL_STATUS_ID=583

lokalise2 --token $API_TOKEN \
          --project-id $PROJECT_ID \
          file download \
          --format strings \
          --filter-langs $LANGUAGES \
          --custom-translation-status-ids $FINAL_STATUS_ID \
          --export-sort "a_z" \
          --directory-prefix "%LANG_ISO%.lproj" \
          --original-filenames=true \
          --unzip-to Stripe3DS2/Stripe3DS2/Resources/

for f in Stripe3DS2/Stripe3DS2/Resources/*.lproj/*.strings
do
    # lokalise doesn't consistently add lines in between keys, but genstrings does
    # so here we add an empty line every two lines (first line is comment, second is key=val)
    TMP_FILE=$(mktemp /tmp/download_localized_strings_from_lokalise.XXXXXX)

    awk 'BEGIN {last_empty = 0; last_content = 0; row = 0;}; {if (NR == last_empty + 3 && NF > 1) {print ""; last_empty = NR - 1} else if (NF <= 1) {last_empty = NR}}; {if (NF > 1) {last_content = NR}}; {row = row + 1}; 1; END {if (row == last_content) {print ""}}' $f > $TMP_FILE && mv $TMP_FILE $f
done

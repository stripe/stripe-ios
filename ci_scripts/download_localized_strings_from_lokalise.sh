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
LANGUAGES="da,de,en-GB,en,es-AR,es,fi,fr-CA,fr,it,ja,ko,nb,nl,nn-NO,pt-BR,pt-PT,ru,sv,tr,zh-HANS,zh-HK,zh-TW"
# Chinese (Traditional) is zh-TW by default in lokalise so we have to map it to zh-Hant
LANG_MAP='[{"original_language_iso":"zh-TW","custom_language_iso":"zh-Hant"}]'

lokalise2 --token $API_TOKEN \
          --project-id $PROJECT_ID \
          file download \
          --format strings \
          --filter-langs $LANGUAGES \
          --language-mapping $LANG_MAP \
          --export-sort "a_z" \
          --directory-prefix "%LANG_ISO%.lproj" \
          --original-filenames=true \
          --unzip-to Stripe/Resources/Localizations/

for f in Stripe/Resources/Localizations/*.lproj/*.strings
do
    # lokalise doesn't add lines in between keys, but genstrings does
    # so here we add an empty line every two lines (first line is comment, second is key=val)
    TMP_FILE=$(mktemp /tmp/download_localized_strings_from_lokalise.XXXXXX)
    awk -v n=2 '1; NR % n == 0 {print ""}' $f > $TMP_FILE && mv $TMP_FILE $f
done

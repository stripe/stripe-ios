#!/bin/bash -e

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

# Load LOCALIZATION_DIRECTORIES variable
source ci_scripts/localization_vars.sh

# Duplicated strings that need to be migrated will have this tag
DUPLICATE_TAG_NAME="migrated-string"

for DIRECTORY in ${LOCALIZATION_DIRECTORIES[@]}
do
  EN_FILENAME="${DIRECTORY}/Resources/Localizations/en.lproj/Localizable.strings"
  LOKALISE_FILENAME="${DIRECTORY}/Resources/Localizations/%LANG_ISO%.lproj/Localizable.strings"

  # Skip this file if the `en.lproj/Localizable.strings` is empty, otherwise
  # Lokalise will error.
  if ! grep -q '[^[:space:]]' "${EN_FILENAME}"
  then
    echo "No strings found in ${EN_FILENAME}... skipping upload."
    continue
  fi

  # Upload to Lokalise
  UPLOAD_RESULT="$(
    lokalise2 --token $API_TOKEN \
              --project-id $PROJECT_ID \
              file upload \
              --file "${EN_FILENAME}" \
              --include-path \
              --lang-iso "en" \
              --poll
  )"

  echo "${UPLOAD_RESULT}"

  # Check if any localized strings were migrated from one module so we can
  # update their filenames to the new module in Lokalise.
  echo "Checking for migrated strings in ${EN_FILENAME}..."

  # Upload a second time, but using `--distinguish-by-file` flag and tagging
  # with `DUPLICATE_TAG_NAME` This will temporarily duplicate keys that Lokalise
  # has associated with another module's Localizable.strings. The tag provides a
  # means to query for the key names that were migrated so we can update their
  # filenames to the new module's Localizable.strings file. We'll then delete the
  # duplicated keys.
  UPLOAD_RESULT="$(
    lokalise2 --token $API_TOKEN \
              --project-id $PROJECT_ID \
              file upload \
              --file "${EN_FILENAME}" \
              --include-path \
              --lang-iso "en" \
              --poll \
              --distinguish-by-file \
              --tags $DUPLICATE_TAG_NAME
  )"

  # Trim first line from outout to get json string
  UPLOAD_RESULT_JSON="$(echo "${UPLOAD_RESULT}" | sed 1d)"

  # Compute the total number strings that were duplicated in the second upload
  SKIPPED_COUNT="$(echo "${UPLOAD_RESULT_JSON}" | jq -r '.process.details.files[0].key_count_skipped')"
  TOTAL_COUNT="$(echo "${UPLOAD_RESULT_JSON}" | jq -r '.process.details.files[0].key_count_total')"
  MIGRATED_STRING_COUNT=`expr $TOTAL_COUNT - $SKIPPED_COUNT`

  if (( MIGRATED_STRING_COUNT > 0 ))
  then
    echo -e "\033[0;31m$MIGRATED_STRING_COUNT migrated string(s) detected.\033[0m"
  else
    # If no strings were migrated, there's nothing else to do
    echo -e "\033[0;32mNo migrated strings detected in ${EN_FILENAME}.\033[0m"
    continue
  fi

  # Get list of keys that were tagged in the previous upload, giving us a list
  # of key names that need to have their filenames updated.
  DUPED_KEYS_RESULT="$(
    lokalise2 --token $API_TOKEN \
              --project-id $PROJECT_ID \
              key list \
              --filter-filenames "${LOKALISE_FILENAME}" \
              --filter-platforms "ios" \
              --filter-tags $DUPLICATE_TAG_NAME
  )"

  # Ids for keys that were duplicated. We'll need to delete these later.
  DUPED_KEY_IDS=($(echo "${DUPED_KEYS_RESULT}" | jq -r '.keys[].key_id'))

  # Key names that need to migrated, comma-separated and string-escaped
  DUPED_KEY_NAMES_JOINED_STRING=$(echo "${DUPED_KEYS_RESULT}" | jq -c '[.keys[].key_name.ios]')
  DUPED_KEY_NAMES_JOINED_STRING=${DUPED_KEY_NAMES_JOINED_STRING#"["}
  DUPED_KEY_NAMES_JOINED_STRING=${DUPED_KEY_NAMES_JOINED_STRING%"]"}

  # Delete the duplicated keys we made in the second upload
  echo "Deleting duplicated strings..."
  INDEX=0
  for KEY_ID in ${DUPED_KEY_IDS[@]}
  do
    KEY_NAME_IOS=$(echo "${DUPED_KEYS_RESULT}" | jq -r ".keys[${INDEX}].key_name.ios")
    echo -e "\tDeleting '\033[0;35m${KEY_NAME_IOS}\033[0m'"

    lokalise2 --token $API_TOKEN \
              --project-id $PROJECT_ID \
              key delete \
              --key-id $KEY_ID \
              > /dev/null    # silence output

    INDEX=$(($INDEX+1))
  done

  # Get the ids for keys that need their filenames updated by their key names
  echo "Migrating to ${LOKALISE_FILENAME}..."
  NEED_MIGRATION_KEYS_RESULT="$(
    lokalise2 --token $API_TOKEN \
              --project-id $PROJECT_ID \
              key list \
              --filter-platforms "ios" \
              --filter-keys "${DUPED_KEY_NAMES_JOINED_STRING}"
  )"

  NEED_MIGRATION_KEY_IDS=($(echo "${NEED_MIGRATION_KEYS_RESULT}" | jq -r '.keys[].key_id'))

  # Update the filename for each of these keys
  INDEX=0
  for KEY_ID in ${NEED_MIGRATION_KEY_IDS[@]}
  do
    # Extract `filenames` json and replace 'ios' value with updated filename.
    # This preserves the filename for Android
    FILENAMES_JSON=$(echo "${NEED_MIGRATION_KEYS_RESULT}" | jq -r ".keys[${INDEX}].filenames | .ios=\"${LOKALISE_FILENAME}\"")

    # Extract `key_name` json (this is a required argument to Lokalise even
    # though we're not modifying it)
    KEYNAME_JSON=$(echo "${NEED_MIGRATION_KEYS_RESULT}" | jq -r ".keys[${INDEX}].key_name")

    # Extract key name and original filename for info printout
    KEY_NAME_IOS=$(echo "${KEYNAME_JSON}" | jq -r ".ios")
    ORIGINAL_FILENAME=$(echo "${NEED_MIGRATION_KEYS_RESULT}" | jq -r ".keys[${INDEX}].filenames.ios")

    echo -e "\tMigrating '\033[0;35m${KEY_NAME_IOS}\033[0m'"
    echo -e "\t     from ${ORIGINAL_FILENAME}"
    lokalise2 --token $API_TOKEN \
              --project-id $PROJECT_ID \
              key update \
              --key-id $KEY_ID \
              --filenames "${FILENAMES_JSON}" \
              --key-name "${KEYNAME_JSON}" \
              > /dev/null    # silence output
    INDEX=$(($INDEX+1))
  done

  echo -e "\033[0;32mFinished migrating to ${LOKALISE_FILENAME}.\033[0m"
done

echo -e "\033[0;32mDone!\033[0m"

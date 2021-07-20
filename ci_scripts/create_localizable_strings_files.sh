#!/bin/bash

# Creates a `Resources/Localizations/{LANGUAGE}.lproj/Localizable.strings`
# directory structure for each directory and language in `localization_vars.sh`
# (plus English) if one doesn't exist already.

# Load LOCALIZATION_DIRECTORIES & LANGUAGES variables
source ci_scripts/localization_vars.sh

IFS=',' read -r -a LANGUAGES_ARRAY <<< "${LANGUAGES},en"

for DIRECTORY in ${LOCALIZATION_DIRECTORIES[@]}
do
  if [ ! -d "${DIRECTORY}/Resources" ]
  then
    mkdir "${DIRECTORY}/Resources"
  fi

  if [ ! -d "${DIRECTORY}/Resources/Localizations" ]
  then
    mkdir "${DIRECTORY}/Resources/Localizations"
  fi

  for LANGUAGE in ${LANGUAGES_ARRAY[@]}
  do
    if [ ! -d "${DIRECTORY}/Resources/Localizations/${LANGUAGE}.lproj" ]
    then
      mkdir "${DIRECTORY}/Resources/Localizations/${LANGUAGE}.lproj"
    fi

    touch "${DIRECTORY}/Resources/Localizations/${LANGUAGE}.lproj/Localizable.strings"
  done
done

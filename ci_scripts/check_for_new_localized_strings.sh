#!/bin/bash

EXIT_CODE=0

# Load LOCALIZATION_DIRECTORIES variable
source ci_scripts/localization_vars.sh

for directory in ${LOCALIZATION_DIRECTORIES[@]}
do
  find ${directory} -name \*.swift ! -name STPLocalizedString.swift -print0 | xargs -0 genstrings -s STPLocalizedString -o "${directory}/Resources/Localizations/en.lproj"

  if [[ $? -eq 0 ]]; then

    # Genstrings outputs in utf16 but we want to store in utf8
    iconv -f utf-16 -t utf-8 "${directory}/Resources/Localizations/en.lproj/Localizable.strings" > "${directory}/Resources/Localizations/en.lproj/Localizable.strings.utf8"

    if [[ $? -eq 0 ]]; then
      rm "${directory}/Resources/Localizations/en.lproj/Localizable.strings"
      mv "${directory}/Resources/Localizations/en.lproj/Localizable.strings.utf8" "${directory}/Resources/Localizations/en.lproj/Localizable.strings"
    else
      echo "Error recoding into utf8 for ${directory}"
      EXIT_CODE=1
    fi
  else
    echo "Error occurred generating english strings file for ${directory}"
    EXIT_CODE=1
  fi

  sh ci_scripts/check_for_invalid_formatting_strings.sh "${directory}"
  if [[ $? -ne 0 ]]; then
      echo "check_for_invalid_formatting_strings.sh detected strings with invalid formatting characters in ${directory}"
      EXIT_CODE=1
  fi

  git diff --quiet --exit-code -- "${directory}/Resources/Localizations/en.lproj/Localizable.strings"
  if [[ $? -ne 0 ]]; then
      echo -e "\t\033[0;31mAdded or deleted strings detected in ${directory}:\033[0m"
      git diff -U0 --color=always -- "${directory}/Resources/Localizations/en.lproj/Localizable.strings" | grep --color=always -E '^(\x1b\[[0-9;]*m)*[+-]' | tail -n +3
      echo -e "\t\033[0;31mIf you removed a string, run ci_scripts/l10n/lint.rb to clean up other languages.\033[0m"
      EXIT_CODE=1
  fi
done

# Check for duplicate strings across modules
./ci_scripts/l10n/check_for_duplicate_localizations.rb
if [[ $? -ne 0 ]]; then
  EXIT_CODE=1
fi

exit $EXIT_CODE

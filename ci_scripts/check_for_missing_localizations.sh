#!/bin/bash

EXIT_CODE=0

# Load LOCALIZATION_DIRECTORIES variable
source ci_scripts/localization_vars.sh

for DIRECTORY in ${LOCALIZATION_DIRECTORIES[@]}
do
  IFS=$'\n' STRINGS=($(awk -F= 'NF <= 1 {next} {print $1}' "${DIRECTORY}/Resources/Localizations/en.lproj/Localizable.strings"))

  for f in ${DIRECTORY}/Resources/Localizations/*.lproj/*.strings
  do
      echo "Checking $f..."
      HAS_MISSING=0
      for VAL in "${STRINGS[@]}"
      do
          ESCAPED_VAL=$(echo "$VAL" | sed 's/'\''/\\'"'"'/g')
          VAL_CHECK_COM='/usr/libexec/PlistBuddy -c "Print :$1" $2 2> /dev/null'
          LOCALIZED_VAL=$(/bin/bash -c "$VAL_CHECK_COM" -- "$ESCAPED_VAL" "$f")

          # If localized value is missing or file is empty
          if [ -z "$LOCALIZED_VAL" ] || ! grep -q '[^[:space:]]' "$f"
          then
              EXIT_CODE=1
              HAS_MISSING=1
              echo -e "\t\033[0;31m$ESCAPED_VAL\033[0m"
          fi
      done
      if [ $HAS_MISSING == 0 ]
      then
          echo -e "\t\033[0;32mAll good!\033[0m"
      fi
  done
done

exit $EXIT_CODE

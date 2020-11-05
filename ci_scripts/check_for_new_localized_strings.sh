#!/bin/bash

find Stripe -name \*.swift ! -name STPLocalizedString.swift -print0 | xargs -0 genstrings -s STPLocalizedString -o Stripe/Resources/Localizations/en.lproj

if [[ $? -eq 0 ]]; then

  if [[ -z $(which recode) ]]; then
    if [[ -z $(which brew) ]]; then
      echo "Please install homebrew or the recode command line tool"
      exit 1
    else
      HOMEBREW_NO_AUTO_UPDATE=1 brew install recode
    fi
  fi

  if [[ $? -eq 0 ]]; then

    # Genstrings outputs in utf16 but we want to store in utf8
    recode utf16..utf8 Stripe/Resources/Localizations/en.lproj/Localizable.strings

  else
    echo "Error recoding into utf8"
    exit 1
  fi
else
  echo "Error occurred generating english strings file."
  exit 1
fi

git diff --quiet --exit-code -- Stripe/Resources/Localizations/en.lproj
if [[ $? -ne 0 ]]; then
    echo -e "\t\033[0;31mNew strings detected\033[0m"
    exit 1
else
    exit 0
fi


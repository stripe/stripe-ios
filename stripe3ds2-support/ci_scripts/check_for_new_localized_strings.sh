#!/bin/bash

find Stripe3DS2 -name \*.m -print0 | xargs -0 genstrings -s STDSLocalizedString -o Stripe3DS2/Stripe3DS2/Resources/en.lproj/

if [[ $? -eq 0 ]]; then
  # Genstrings outputs in utf16 but we want to store in utf8
  iconv -f utf-16 -t utf-8 Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings > Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings.utf8
  
  if [[ $? -eq 0 ]]; then
    rm Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings
    mv Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings.utf8 Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings
  else
    echo "Error recoding into utf8"
    exit 1
  fi
else
  echo "Error occurred generating english strings file."
  exit 1
fi

git diff --quiet --exit-code -- Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings
if [[ $? -ne 0 ]]; then
    echo -e "\t\033[0;31mNew strings detected\033[0m"
    exit 1
else
    exit 0
fi


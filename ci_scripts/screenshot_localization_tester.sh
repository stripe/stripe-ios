#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z $(which xcparse) ]]; then
    echo "Installing xcparse via homebrew..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install chargepoint/xcparse/xcparse
fi

# Load LANGUAGES variables
source ci_scripts/localization_vars.sh

#IFS=',' read -r -a LANGUAGES_ARRAY <<< ${LANGUAGES}
#for LANGUAGE in ${LANGUAGES_ARRAY[@]}
#do
LANGUAGE="ms-MY"

  # Generate PaymentSheet screenshots
  xcodebuild -quiet test -workspace "${script_dir}/../Stripe.xcworkspace" -scheme "PaymentSheetLocalizationScreenshotGenerator" -configuration "Debug" -derivedDataPath build-ci-tests -sdk "iphonesimulator" -destination "platform=iOS Simulator,name=iPhone 12 mini,OS=15.4" -resultBundlePath "${script_dir}/../build/loc_qa/${LANGUAGE}_payment_sheet" -testLanguage $LANGUAGE -testRegion $LANGUAGE
  retVal=$?
  if [ $retVal -ne 0 ]; then
    exit 1
  fi


  # Generate legacy (Basic Integration) screenshots
  xcodebuild -quiet test -workspace "${script_dir}/../Stripe.xcworkspace" -scheme "LocalizationTester" -configuration "Debug" -derivedDataPath build-ci-tests -sdk "iphonesimulator" -destination "platform=iOS Simulator,name=iPhone 12 mini,OS=15.4" -resultBundlePath "${script_dir}/../build/loc_qa/${LANGUAGE}_legacy_ui" -testLanguage $LANGUAGE -testRegion $LANGUAGE

  retVal=$?
  if [ $retVal -ne 0 ]; then
    exit 1
  fi
  
  # Parse out screenshots from xcresult
  xcparse screenshots "${script_dir}/../build/loc_qa/${LANGUAGE}_payment_sheet.xcresult" "${script_dir}/../build/loc_qa/${LANGUAGE}_screenshots/"
  xcparse screenshots "${script_dir}/../build/loc_qa/${LANGUAGE}_legacy_ui.xcresult" "${script_dir}/../build/loc_qa/${LANGUAGE}_screenshots/"
#done

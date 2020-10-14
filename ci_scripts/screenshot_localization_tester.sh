#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v xcpretty > /dev/null; then

  info "Installing xcpretty..."
  gem install xcpretty --no-document || die "Executing \`gem install xcpretty\` failed"
fi

if [[ -z $(which xcparse) ]]; then
    echo "Installing xcparse via homebrew..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew install chargepoint/xcparse/xcparse
fi

for i in en,US zh-HANS,CN de,DE es,ES it,IT ja,JP nl,NL fr,FR fi,FI nb,NO da,DK pt-BR,BR pt-PT,PT sv,SE es-AR,AR fr-CA,CA nn,NO, en,GB ko,ko ru,ru tr,tr; do
  #statements
  IFS=",";
  set -- $i;
  xcodebuild clean test -workspace "${script_dir}/../Stripe.xcworkspace" -scheme "LocalizationTester" -configuration "Debug" -sdk "iphonesimulator" -destination "platform=iOS Simulator,name=iPhone 6s,OS=11.4" -resultBundlePath "${script_dir}/../build/loc_qa/$1_$2" -testLanguage $1 -testRegion $2 | xcpretty
  xcparse screenshots "${script_dir}/../build/loc_qa/$1_$2.xcresult" "${script_dir}/../build/loc_qa/$1_$2_screenshots"
done

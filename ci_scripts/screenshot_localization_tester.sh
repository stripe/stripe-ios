#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for i in en,US zh-HANS,CN de,DE es,ES it,IT ja,JP nl,NL fr,FR fi,FI nb,NO da,DK pt-BR,BR pt-PT,PT sv,SE es-AR,AR fr-CA,CA nn,NO; do
  #statements
  IFS=",";
  set -- $i;
  xcodebuild clean test -workspace "${script_dir}/../Stripe.xcworkspace" -scheme "LocalizationTester" -configuration "Debug" -sdk "iphonesimulator" -destination "platform=iOS Simulator,name=iPhone 6s,OS=11.4" -resultBundlePath "${script_dir}/../build/loc_qa/$1_$2" -testLanguage $1 -testRegion $2
done

for i in en,US zh-HANS,CN de,DE es,ES it,IT ja,JP nl,NL fr,FR fi,FI nb,NO da,DK pt-BR,BR pt-PT,PT sv,SE es,AR fr,CA nn,NO; do
  #statements
  IFS=",";
  set -- $i;
  # echo "/Users/csabol/Desktop/loc_qa/$1_$2"
  xcodebuild clean test -workspace "Stripe.xcworkspace" -scheme "LocalizationTester" -configuration "Debug" -sdk "iphonesimulator" -destination "platform=iOS Simulator,name=iPhone 6s,OS=11.4" -resultBundlePath "/Users/csabol/Desktop/loc_qa/$1_$2" -testLanguage $1 -testRegion $2
done

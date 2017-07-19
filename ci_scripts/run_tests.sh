set -euf -o pipefail

carthage bootstrap --platform ios --configuration Release --no-use-binaries
cd Example; carthage bootstrap --platform ios; cd ..

gem install xcpretty --no-ri --no-rdoc
xcodebuild clean build build-for-testing -workspace Stripe.xcworkspace -scheme "StripeiOS" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1' | xcpretty -c
xcodebuild test-without-building -workspace Stripe.xcworkspace -scheme "StripeiOS" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1' | xcpretty -c
xcodebuild build -workspace Stripe.xcworkspace -scheme "Standard Integration (Swift)" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1'  | xcpretty -c
xcodebuild build -workspace Stripe.xcworkspace -scheme "Custom Integration (ObjC)" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1' | xcpretty -c

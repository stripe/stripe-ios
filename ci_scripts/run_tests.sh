set -euf -o pipefail

carthage bootstrap --platform ios --configuration Release --no-use-binaries

gem install xcpretty --no-ri --no-rdoc
xcodebuild test -workspace Stripe.xcworkspace -scheme "StripeiOS" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.2' | xcpretty -c
xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Simple)" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.2'  | xcpretty -c
xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Custom)" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.2' | xcpretty -c

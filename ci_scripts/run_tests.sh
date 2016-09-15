set -euf -o pipefail

gem install xcpretty --no-ri --no-rdoc
xcodebuild test -workspace Stripe.xcworkspace -scheme "StripeiOS Tests" -configuration Debug -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' | xcpretty -c
xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Simple)" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' | xcpretty -c
xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Custom)" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' | xcpretty -c

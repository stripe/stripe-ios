gem install xcpretty --no-ri --no-rdoc
set -euf -o pipefail && xcodebuild test -workspace Stripe.xcworkspace -scheme "StripeiOS Tests" -configuration Debug -sdk iphonesimulator | xcpretty -c
set -euf -o pipefail && xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Simple)" -sdk iphonesimulator | xcpretty -c
set -euf -o pipefail && xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Custom)" -sdk iphonesimulator | xcpretty -c

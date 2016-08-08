gem install xcpretty --no-ri --no-rdoc
export PYTHONUSERBASE=~/.local
easy_install --user scan-build
export PATH="${HOME}/.local/bin:${PATH}"
set -euf -o pipefail && xcodebuild test -workspace Stripe.xcworkspace -scheme "StripeiOS Tests" -configuration Debug -sdk iphonesimulator | xcpretty -c
set -o pipefail && scan-build --status-bugs xcodebuild analyze -workspace Stripe.xcworkspace -scheme "StripeiOS" -configuration Debug -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO | xcpretty
set -euf -o pipefail && xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Simple)" -sdk iphonesimulator | xcpretty -c
set -euf -o pipefail && xcodebuild build -workspace Stripe.xcworkspace -scheme "Stripe iOS Example (Custom)" -sdk iphonesimulator | xcpretty -c

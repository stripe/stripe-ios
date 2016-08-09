gem install xcpretty --no-ri --no-rdoc
export PYTHONUSERBASE=~/.local
easy_install --user scan-build
export PATH="${HOME}/.local/bin:${PATH}"
set -o pipefail && scan-build --status-bugs --use-analyzer Xcode xcodebuild analyze -workspace Stripe.xcworkspace -scheme "StripeiOS" -configuration Debug -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO | xcpretty

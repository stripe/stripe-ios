#!/bin/bash
# Set up Tuist in Xcode Cloud

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${script_dir}/.."

mkdir tuist-bin
curl -L https://github.com/tuist/tuist/releases/download/`cat .tuist-version`/tuist.zip > tuist-bin/tuist.zip
unzip tuist-bin/tuist.zip -d tuist-bin/
cd "${script_dir}/.."
./tuist-bin/tuist generate -n
xcodebuild -resolvePackageDependencies -workspace Stripe.xcworkspace -scheme "PaymentSheet Example"
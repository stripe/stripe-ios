#!/bin/sh

log_file="${TMPDIR}/xcodebuild_analyze.log"

# Reset log file
echo "Resetting log file..."
rm -f "${log_file}"

# Run static analyzer
echo "Running static analyzer..."
xcodebuild clean analyze \
  -quiet \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination 'generic/platform=iOS Simulator' \
  ONLY_ACTIVE_ARCH=NO \
  OTHER_LDFLAGS="\$(inherited) -Wl,-no_compact_unwind" \
  | tee "${log_file}"

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  echo "ERROR: xcodebuild exited with non-zero status code: ${exit_code}"
  exit 1
fi

# Search for warnings in log file
echo "Searching for static analyzer warnings..."

# Fun note:
# xcodebuild outputs a line like "...SomeFile.m:36:1: warning: foo"
# ...but sometimes, it inserts spurious newlines everywhere
grep "\bwarning\b" "${log_file}" > "/dev/null"

if [[ "$?" != 1 ]]; then
  echo "ERROR: Found static analyzer warnings!"
  exit 1
fi

echo "All good!"

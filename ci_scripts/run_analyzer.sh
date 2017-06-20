#!/bin/sh

log_file="${TMPDIR}/xcodebuild_analyze.log"

# Install xcpretty
if ! command -v xcpretty > /dev/null; then
  echo "Installing xcpretty..."
  gem install xcpretty --no-ri --no-rdoc
fi

# Reset log file
echo "Resetting log file..."
rm -f "${log_file}"

# Run static analyzer
echo "Running static analyzer..."
xcodebuild clean analyze \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  ONLY_ACTIVE_ARCH=NO \
  | tee "${log_file}" \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  echo "ERROR: xcodebuild exited with non-zero status code: ${exit_code}"
  exit 1
fi

# Search for warnings in log file
echo "Searching for static analyzer warnings..."
grep "warning:" "${log_file}" > "/dev/null"

if [[ "$?" != 1 ]]; then
  echo "ERROR: Found static analyzer warnings!"
  exit 1
fi

echo "All good!"

#!/bin/sh

log_file="${TMPDIR}/xcodebuild_analyze.log"

# Reset log file
echo "Resetting log file..."
rm -f "${log_file}"

# Run static analyzer
echo "Running static analyzer..."
xcodebuild clean analyze \
  -quiet \
  -project "Stripe3DS2/Stripe3DS2.xcodeproj" \
  -scheme "Stripe3DS2" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
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
grep "warning:" "${log_file}" > "/dev/null"

if [[ "$?" != 1 ]]; then
  echo "ERROR: Found static analyzer warnings!"
  exit 1
fi

echo "All good!"


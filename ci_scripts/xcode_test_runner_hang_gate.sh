#!/usr/bin/env bash
#
# Gate script for recovering from the intermittent Xcode parallel-testing flake:
#
#   "<Runner> encountered an error (The test runner hung before establishing connection.)"
#
# When xcodebuild runs with `-parallel-testing-enabled YES`, it clones the base
# simulator and launches a separate XCUITest runner in each clone. On the CI
# machines a clone's runner occasionally fails to establish its IPC connection
# back to xcodebuild within the launch timeout. xcodebuild then exits non-zero
# even though every test that actually ran passed. `-retry-tests-on-failure`
# does NOT recover from this because it is not a test-case failure.
#
# This script is run immediately after an (is_skippable) xcode-test step. It
# inspects the raw xcodebuild log and decides whether to retry the whole shard:
#
#   - Attempt succeeded            -> exit 0 (nothing to do).
#   - A real test case failed      -> exit 1 (fail the build; NEVER masked).
#   - Only the runner-hang flake   -> set STRIPE_RETRY_XCODE_TEST=yes, exit 0
#                                     so a second xcode-test step (guarded by
#                                     run_if) re-runs the shard once.
#   - Anything else (compile error,
#     unknown failure)             -> exit 1 (fail the build).
#
# The bias is intentional: unless we positively identify the failure as the
# runner-hang flake AND see no real test-case failures, we fail the build.

set -euo pipefail

RESULT="${BITRISE_XCODE_TEST_RESULT:-}"
LOG_PATH="${BITRISE_XCODEBUILD_TEST_LOG_PATH:-}"

if [ "$RESULT" = "succeeded" ]; then
  echo "xcode-test succeeded; no retry needed."
  exit 0
fi

echo "xcode-test result: '${RESULT:-unknown}'. Inspecting raw log to classify the failure."

if [ -z "$LOG_PATH" ] || [ ! -f "$LOG_PATH" ]; then
  echo "No raw xcodebuild log available (BITRISE_XCODEBUILD_TEST_LOG_PATH='${LOG_PATH}'). Treating as a real failure."
  exit 1
fi

# Never mask a genuine test-case failure. xcodebuild's raw log prints
# "Test case '-[Suite testX]' failed ..." for each failing case and a
# "Failing tests:" summary block. Match case-insensitively to be safe.
if grep -qiE "test case '.*' failed" "$LOG_PATH" || grep -qE "^Failing tests:" "$LOG_PATH"; then
  echo "Detected at least one real test-case failure. Not retrying — failing the build."
  exit 1
fi

# No real test failures. Was the only problem a parallel-worker runner that
# hung before establishing its connection?
if grep -qi "hung before establishing connection" "$LOG_PATH"; then
  echo "Detected 'test runner hung before establishing connection' with no failing test cases."
  echo "This is the parallel-testing simulator-clone flake. Retrying the shard once."
  envman add --key STRIPE_RETRY_XCODE_TEST --value yes
  exit 0
fi

echo "xcode-test failed for an unrecognized reason (no failing test cases and no runner-hang signature)."
echo "Not retrying — failing the build so the failure is investigated."
exit 1

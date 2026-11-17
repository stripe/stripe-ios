#!/usr/bin/env bash
#
# GitHub Actions equivalent of Bitrise's xcode-test step followed by
# xcode_test_runner_hang_gate.sh and its guarded retry.
#
# Usage: xcode_test.sh --scheme NAME [--test-plan NAME] [--destination DEST] [--name LABEL] [-- xcodebuild options...]
#
# Failed test cases are retried once in-process (-retry-tests-on-failure -test-iterations 2).
# If the run fails only because a parallel-testing runner hung before connecting,
# the whole run is repeated once.

set -euo pipefail

scheme=""
test_plan=""
destination="${DEFAULT_TEST_DEVICE:-}"
name=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scheme) scheme="$2"; shift 2 ;;
    --test-plan) test_plan="$2"; shift 2 ;;
    --destination) destination="$2"; shift 2 ;;
    --name) name="$2"; shift 2 ;;
    --) shift; break ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$scheme" ] || [ -z "$destination" ]; then
  echo "--scheme and --destination (or DEFAULT_TEST_DEVICE) are required" >&2
  exit 1
fi

name="${name:-${scheme}${test_plan:+-$test_plan}}"
safe_name="$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '_')"
output_dir="${BITRISE_DEPLOY_DIR:-${RUNNER_TEMP:-/tmp}/deploy}"
mkdir -p "$output_dir"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_attempt() {
  local attempt="$1"
  shift
  local log_path="$output_dir/${safe_name}-attempt${attempt}.log"
  local result_bundle="$output_dir/${safe_name}-attempt${attempt}.xcresult"
  rm -rf "$result_bundle"

  local args=(test -workspace Stripe.xcworkspace -scheme "$scheme" -destination "$destination"
    -resultBundlePath "$result_bundle" -retry-tests-on-failure -test-iterations 2
    COMPILER_INDEX_STORE_ENABLE=NO)
  if [ -n "$test_plan" ]; then
    args+=(-testPlan "$test_plan")
  fi
  args+=("$@")

  echo "::group::xcodebuild ${args[*]}"
  echo "xcodebuild ${args[*]}"
  echo "::endgroup::"

  set +e
  set -o pipefail
  xcodebuild "${args[@]}" 2>&1 | tee "$log_path" | xcbeautify --renderer github-actions
  local status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    BITRISE_XCODE_TEST_RESULT=succeeded
  else
    BITRISE_XCODE_TEST_RESULT=failed
  fi
  export BITRISE_XCODE_TEST_RESULT
  export BITRISE_XCODEBUILD_TEST_LOG_PATH="$log_path"
  return "$status"
}

if run_attempt 1 "$@"; then
  exit 0
fi

retry_env="$(mktemp)"
ENVMAN_ENV_FILE="$retry_env" PATH="$script_dir/bin:$PATH" "$script_dir/../xcode_test_runner_hang_gate.sh"
if grep -q '^yes$' "$retry_env"; then
  echo "Retrying $name after a test-runner hang."
  run_attempt 2 "$@"
else
  exit 1
fi

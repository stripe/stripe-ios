#!/bin/bash

# setup_simulator.sh
# Routes simulator setup to the implementation for the active Xcode version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCODE_MAJOR_VERSION="$(xcodebuild -version | sed -n '1s/^Xcode \([0-9][0-9]*\).*/\1/p')"

if [ -z "$XCODE_MAJOR_VERSION" ]; then
    echo "Error: Unable to determine the active Xcode version" >&2
    return 1
fi

if [ "$XCODE_MAJOR_VERSION" -ge 27 ]; then
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/setup_simulator_xcode_27.sh" "$@"
else
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/setup_simulator_xcode_26.sh" "$@"
fi

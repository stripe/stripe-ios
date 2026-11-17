#!/bin/bash
set -euo pipefail

# Opt in per workflow so existing release and TestFlight workflows keep working.
[[ "${STRIPE_XCODE_CLOUD_CI:-0}" == "1" ]] || exit 0
cd "${CI_PRIMARY_REPOSITORY_PATH:?Xcode Cloud must provide the source checkout}"

case "${STRIPE_CI_TASK:-tests}" in
    tests) python3 ci_scripts/xcode_cloud/prepare.py source ;;
    quality|installation)
        source ci_scripts/xcode_cloud/dependencies.sh
        "ci_scripts/xcode_cloud/${STRIPE_CI_TASK}.sh"
        ;;
    *) echo "error: STRIPE_CI_TASK must be tests, quality, or installation" >&2; exit 1 ;;
esac

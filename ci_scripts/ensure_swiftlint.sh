#!/bin/bash

# ensure_swiftlint.sh
#
# Ensures a pinned version of SwiftLint is available and exports its path as
# $SWIFTLINT for the caller to invoke.
#
# The pinned version is read from the `.swiftlint-version` file at the repo
# root. If the locally-installed `swiftlint` already matches, it is used as-is;
# otherwise the exact release binary is downloaded from GitHub and cached under
# ~/.cache/stripe-ios/swiftlint/<version>/ so that CI and local runs always lint
# with the same version (RUN_MOBILESDK-5167).
#
# Usage (from another script):
#   source "<path to>/ensure_swiftlint.sh"
#   "$SWIFTLINT" --strict ...
#
# On failure this script calls `exit 1`, which terminates the sourcing script.

_ensure_swiftlint_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_swiftlint_version_file="${_ensure_swiftlint_dir}/../.swiftlint-version"

if [ ! -f "$_swiftlint_version_file" ]; then
  echo "error: missing $(cd "$(dirname "$_swiftlint_version_file")" && pwd)/.swiftlint-version" >&2
  exit 1
fi

SWIFTLINT_VERSION="$(tr -d '[:space:]' < "$_swiftlint_version_file")"

# `swiftlint --version` prints just the version number, e.g. "0.59.1".
_installed_swiftlint_version() {
  command -v swiftlint >/dev/null 2>&1 || return 1
  swiftlint --version 2>/dev/null | tr -d '[:space:]'
}

# 1. Prefer a system swiftlint that already matches the pinned version.
if [ "$(_installed_swiftlint_version)" == "$SWIFTLINT_VERSION" ]; then
  export SWIFTLINT="swiftlint"
  return 0 2>/dev/null || exit 0
fi

# 2. Otherwise download (and cache) the exact pinned release from GitHub.
_swiftlint_cache_dir="${HOME}/.cache/stripe-ios/swiftlint/${SWIFTLINT_VERSION}"
export SWIFTLINT="${_swiftlint_cache_dir}/swiftlint"

if [ ! -x "$SWIFTLINT" ]; then
  echo "SwiftLint ${SWIFTLINT_VERSION} (pinned in .swiftlint-version) not found; downloading..."
  mkdir -p "$_swiftlint_cache_dir"
  _swiftlint_zip_url="https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/portable_swiftlint.zip"
  _swiftlint_tmp_zip="$(mktemp -t swiftlint.XXXXXX.zip)"
  if ! curl --fail --location --silent --show-error --output "$_swiftlint_tmp_zip" "$_swiftlint_zip_url"; then
    echo "error: failed to download SwiftLint ${SWIFTLINT_VERSION} from ${_swiftlint_zip_url}" >&2
    rm -f "$_swiftlint_tmp_zip"
    exit 1
  fi
  unzip -o -q "$_swiftlint_tmp_zip" swiftlint -d "$_swiftlint_cache_dir"
  rm -f "$_swiftlint_tmp_zip"
  chmod +x "$SWIFTLINT"
fi

# Sanity-check the resolved binary reports the pinned version.
_resolved_version="$("$SWIFTLINT" --version 2>/dev/null | tr -d '[:space:]')"
if [ "$_resolved_version" != "$SWIFTLINT_VERSION" ]; then
  echo "error: SwiftLint at ${SWIFTLINT} reports '${_resolved_version}', expected '${SWIFTLINT_VERSION}'" >&2
  exit 1
fi

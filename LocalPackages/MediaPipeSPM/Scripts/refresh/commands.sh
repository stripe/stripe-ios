#!/usr/bin/env bash

require_refresh_tools() {
  local tools=(pod xcrun xcodebuild lipo ditto clang)
  local tool

  for tool in "${tools[@]}"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "error: required tool '${tool}' was not found" >&2
      exit 1
    fi
  done
}

run_command() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  "$@"
}

capture_command() {
  "$@"
}

reset_directory() {
  rm -rf "$1"
  mkdir -p "$1"
}

copy_directory_contents() {
  local source="$1"
  local destination="$2"

  if [[ ! -d "${source}" ]]; then
    echo "error: missing expected directory: ${source}" >&2
    exit 1
  fi

  rm -rf "${destination}"
  run_command ditto "${source}" "${destination}"
}

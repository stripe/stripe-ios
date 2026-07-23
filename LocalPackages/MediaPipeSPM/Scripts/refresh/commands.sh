#!/usr/bin/env bash

require_refresh_tools() {
  local tools=(pod xcodebuild ditto lipo)
  local tool

  for tool in "${tools[@]}"; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "error: required tool '${tool}' was not found" >&2
      exit 1
    fi
  done

  if [[ ! -x /usr/libexec/PlistBuddy ]]; then
    echo "error: required tool '/usr/libexec/PlistBuddy' was not found" >&2
    exit 1
  fi
}

run_command() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
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

strip_intel_simulator_slice() {
  local xcframework_dir="$1"
  local framework_name="$2"
  local old_identifier="ios-arm64_x86_64-simulator"
  local new_identifier="ios-arm64-simulator"
  local old_slice_dir="${xcframework_dir}/${old_identifier}"
  local new_slice_dir="${xcframework_dir}/${new_identifier}"
  local slice_dir="${old_slice_dir}"
  local plist_path="${xcframework_dir}/Info.plist"

  if [[ ! -d "${slice_dir}" ]]; then
    slice_dir="${new_slice_dir}"
  fi

  if [[ ! -d "${slice_dir}" ]]; then
    echo "error: missing expected simulator slice in ${xcframework_dir}" >&2
    exit 1
  fi

  local binary_path="${slice_dir}/${framework_name}.framework/${framework_name}"
  require_file "${binary_path}"

  if lipo -info "${binary_path}" | grep -q 'x86_64'; then
    run_command lipo "${binary_path}" -remove x86_64 -output "${binary_path}.arm64"
    run_command mv "${binary_path}.arm64" "${binary_path}"
  fi

  if [[ -d "${old_slice_dir}" ]]; then
    run_command mv "${old_slice_dir}" "${new_slice_dir}"
  fi

  run_command /usr/libexec/PlistBuddy -c "Set :AvailableLibraries:1:LibraryIdentifier ${new_identifier}" "${plist_path}"

  if /usr/libexec/PlistBuddy -c "Print :AvailableLibraries:1:SupportedArchitectures:1" "${plist_path}" >/dev/null 2>&1; then
    run_command /usr/libexec/PlistBuddy -c "Delete :AvailableLibraries:1:SupportedArchitectures:1" "${plist_path}"
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "error: missing expected file: $1" >&2
    exit 1
  fi
}

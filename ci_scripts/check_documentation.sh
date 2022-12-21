#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
temp_docs_dir="${script_dir}/../temp_docs"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function error {
  echo "[$(basename "${0}")] [ERROR] ${1}"
}

function die {
  error ${0}
  trap cleanup exit 1
}

# Create fresh temp directory to build docs to
rm -rf "${temp_docs_dir}"
mkdir "${temp_docs_dir}"

# Build docs
ruby ${script_dir}/build_documentation.rb --docs-root-dir ${temp_docs_dir}

if [[ "$?" != 0 ]]
then
  die "Unable to build documentation"
fi

found_undocumented=false
exit_code=0

# Check for undocumented warnings
undocumented_json_files=($(find "${temp_docs_dir}" -name "undocumented.json"))
for undocumented_json in ${undocumented_json_files[@]}
do
  undocumented_symbols=$(cat "${undocumented_json}" | jq '.warnings | map(select(.warning=="undocumented"))')

  if [[ "${undocumented_symbols}" != "[]" ]]
  then
    error "Found undocumented symbols in ${undocumented_json}:"
    cat "${undocumented_json}"; echo
    found_undocumented=true
  fi
done

if [ $found_undocumented = true ]
then
  exit_code=1
  error "Less than 100% documentation coverage! See undocumented.json output above."
fi

# Check for `@_spi` references until Jazzy allows SPI-public to be ignored.
# https://github.com/realm/jazzy/issues/1263
spi_grep=$(grep -r -A 1 "@_spi" "${temp_docs_dir}")
if [[ -n $spi_grep ]]
then
  exit_code=1
  echo "${spi_grep}"; echo
  error "@_spi documentation detected. Add \`:nodoc:\` to SPI-public exposed symbols."
fi

if [[ "$exit_code" != 0 ]]
then
  exit $exit_code
fi

info "All good!"

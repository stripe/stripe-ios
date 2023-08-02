#!/bin/bash

ORIGINAL_IFS="$IFS"
IFS=$'\n'

script_dir="$(dirname "$0")"
pushd "${script_dir}/../" > /dev/null 2>&1 || exit 1
stripe_ios_dir="$(pwd)"
popd >/dev/null > /dev/null 2>&1 || exit 1

SHOULD_FAIL=0
subdirs=$(find "${stripe_ios_dir}" -type d -maxdepth 1 -mindepth 1)
for subdir in $subdirs; do
    dirname=$(basename "$subdir")
    if [[ -d "${subdir}" ]] && [[ x"${dirname}" != x"build" ]]; then
	while IFS= read -r -d '' png
	do
	    OUTPUT=$(file "${png}")
	    if echo "${OUTPUT}" | grep -e "-bit"; then
		if ! echo "${OUTPUT}" | grep -e "8-bit" > /dev/null 2>&1; then
		    echo "[ERROR] Image found as non 8-bit PNG image: ${png}"
		    SHOULD_FAIL=1
		fi		
	    fi
	done <  <(find "${subdir}" -type f -path '*Resources*.png' -print0)
    fi
done

IFS="$ORIGINAL_IFS"

if [ ${SHOULD_FAIL} -eq 1 ]; then
    exit 1
fi

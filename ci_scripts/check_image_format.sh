#!/bin/bash

ORIGINAL_IFS="$IFS"
IFS=$'\n'

script_dir=`dirname $0`
pushd "${script_dir}/../" > /dev/null 2>&1
stripe_ios_dir="`pwd`"
popd >/dev/null > /dev/null 2>&1

SHOULD_FAIL=0
for subdir in `ls ${stripe_ios_dir}`; do
    TEMPNODE="${stripe_ios_dir}/${subdir}"
    if [[ -d "${TEMPNODE}" ]] && [[ x"${subdir}" != x"build" ]]; then
	for png in `find "${TEMPNODE}" -type f -path '*Resources*.png'`; do
	    OUTPUT=`file "${png}"`

	    echo ${OUTPUT} | grep -e "-bit"
	    if [ $? -eq 0 ]; then
		echo ${OUTPUT} | grep -e "8-bit" > /dev/null 2>&1
		if [ $? -ne 0 ]; then    
		    echo "[ERROR] Image found as non 8-bit PNG image: ${png}"
		    SHOULD_FAIL=1
		fi		
	    fi
	done
    fi
done

IFS="$ORIGINAL_IFS"

if [ ${SHOULD_FAIL} -eq 1 ]; then
    exit 1
fi

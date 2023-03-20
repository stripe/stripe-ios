#!/bin/bash

IFS=$'\n' STRINGS=($(awk -F= 'NF <= 1 {next} {print $1}' Stripe3DS2/Stripe3DS2/Resources/en.lproj/Localizable.strings))

EXIT_CODE=0
for f in Stripe3DS2/Stripe3DS2/Resources/*.lproj/*.strings
do
    echo "Checking $f..."
    HAS_MISSING=0
    for VAL in "${STRINGS[@]}"
    do
        ESCAPED_VAL=$(echo "$VAL" | sed 's/'\''/\\'"'"'/g')
        VAL_CHECK_COM='/usr/libexec/PlistBuddy -c "Print :$1" $2 2> /dev/null'
        LOCALIZED_VAL=$(/bin/bash -c "$VAL_CHECK_COM" -- "$ESCAPED_VAL" "$f")
        if [ -z "$LOCALIZED_VAL" ]
        then
            EXIT_CODE=1
            HAS_MISSING=1
            echo -e "\t\033[0;31m$ESCAPED_VAL\033[0m"
        fi
    done
    if [ $HAS_MISSING == 0 ]
    then
        echo -e "\t\033[0;32mAll good!\033[0m"
    fi
done

exit $EXIT_CODE



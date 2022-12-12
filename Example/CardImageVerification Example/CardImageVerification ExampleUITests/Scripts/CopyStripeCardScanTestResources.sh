#!/bin/sh
STATIC_LIB_NAME=StripeCardScan
BUNDLE_NAME=$STATIC_LIB_NAME.framework

RESOURCES_FOLDER_NAME=""

# MacOS uses a deep bundle format for resources, placing them in a "Resources" sub-folder.
if [ "$BUNDLE_FORMAT" = "deep" ]; then
    RESOURCES_FOLDER_NAME="$BUNDLE_CONTENTS_FOLDER_PATH/Resources/"
fi

SRC_RESOURCES="$SOURCE_ROOT/../../StripeCardScan/StripeCardScanTests/Resources/"
DST_RESOURCES="$CONFIGURATION_BUILD_DIR/$BUNDLE_NAME/$RESOURCES_FOLDER_NAME"
LOG_PATH=$SYMROOT/$STATIC_LIB_NAME.log

# Make sure to log the results of the copy to enable debugging.
if [ -r "$LOG_PATH" ]; then
    rm $LOG_PATH
fi
touch $LOG_PATH

# Copy
echo "Copying resources from $SRC_RESOURCES to $DST_RESOURCES"

if [ -r "$SRC_RESOURCES" -a -r "$DST_RESOURCES" ]; then
    #rsync -rv --exclude "*" --include "*_test_image.*" "$SRC_RESOURCES" "$DST_RESOURCES" >> $LOG_PATH 2>&1
    for i in $(eval echo "{0..$SCRIPT_INPUT_FILE_LIST_COUNT}")
    do
        LOOP_VALUE="SCRIPT_INPUT_FILE_$i"
        rsync -rv "${!LOOP_VALUE}" "$DST_RESOURCES" >> $LOG_PATH 2>&1
    done
    echo "Success!  Build log at $LOG_PATH"
else
    echo "Source or Dest does not exist"
    exit 1
fi

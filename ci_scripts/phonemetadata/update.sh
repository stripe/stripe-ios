#!/usr/bin/env bash

set -e

VERSION="$1"
if [[ -z "$VERSION" ]]; then
    echo "Please specify a libphonenumber version." >/dev/stderr
    exit 1
fi

RELEASE_URL="https://github.com/google/libphonenumber/archive/refs/tags/v$VERSION.zip"
TMP_DIR=$(mktemp -d)

function cleanup {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Paths
SRC_ZIP_PATH="$TMP_DIR/libphonenumber.zip"
SRC_XML_PATH="$TMP_DIR/PhoneNumberMetadata.xml"
OUTPUT_PATH="StripeUICore/StripeUICore/Resources/JSON/phone_metadata.json.lzfse"

echo "Downloading v$VERSION..."
curl --location --silent --fail --show-error --output "$SRC_ZIP_PATH" "$RELEASE_URL"

echo "Extracting metadata..."
unzip -p "$SRC_ZIP_PATH" "libphonenumber-$VERSION/resources/PhoneNumberMetadata.xml" > "$SRC_XML_PATH"

echo "Processing..."
./ci_scripts/phonemetadata/extract.rb -c "$SRC_XML_PATH" "$OUTPUT_PATH"

echo "DONE!"

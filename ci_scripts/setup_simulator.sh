#!/bin/bash

# setup_simulator.sh
# Automatically finds or creates an iPhone 12 mini with iOS 16.4 for testing
# Caches the result to .stripe-ios-config for reuse

set -e

CONFIG_FILE=".stripe-ios-config"
DEVICE_TYPE="iPhone 12 mini"
IOS_VERSION="16.4"
SIMULATOR_NAME="iPhone 12 mini (Stripe)"

# Function to clear cache
clear_cache() {
    if [ -f "$CONFIG_FILE" ]; then
        echo "Clearing simulator cache..."
        rm "$CONFIG_FILE"
    fi
}

# Function to find existing simulator
find_existing_simulator() {
    xcrun simctl list devices available | grep "$DEVICE_TYPE.*$IOS_VERSION" | head -1 | grep -o "([^)]*)" | tr -d "()"
}

# Function to create new simulator
create_simulator() {
    echo "Creating new $DEVICE_TYPE simulator with iOS $IOS_VERSION..."
    xcrun simctl create "$SIMULATOR_NAME" "com.apple.CoreSimulator.SimDeviceType.iPhone-12-mini" "com.apple.CoreSimulator.SimRuntime.iOS-16-4"
}

# Function to validate simulator exists
validate_simulator() {
    local device_id="$1"
    xcrun simctl list devices | grep -q "$device_id"
}

# Main logic
main() {
    # Handle --clear-cache flag
    if [ "$1" = "--clear-cache" ]; then
        clear_cache
        echo "Cache cleared. Run again to set up simulator."
        exit 0
    fi
    
    # Check if cached config exists and is valid
    if [ -f "$CONFIG_FILE" ] && grep -q "DEVICE_ID_FROM_USER_SETTINGS=" "$CONFIG_FILE"; then
        source "$CONFIG_FILE"
        
        # Validate cached simulator still exists
        if validate_simulator "$DEVICE_ID_FROM_USER_SETTINGS"; then
            echo "✅ Using cached simulator: $DEVICE_ID_FROM_USER_SETTINGS"
            echo "DEVICE_ID_FROM_USER_SETTINGS=$DEVICE_ID_FROM_USER_SETTINGS"
            exit 0
        else
            echo "⚠️  Cached simulator no longer exists, finding new one..."
            clear_cache
        fi
    fi
    
    # Look for existing simulator
    EXISTING_DEVICE=$(find_existing_simulator)
    
    if [ -n "$EXISTING_DEVICE" ]; then
        echo "Found existing $DEVICE_TYPE: $EXISTING_DEVICE"
        DEVICE_ID="$EXISTING_DEVICE"
    else
        DEVICE_ID=$(create_simulator)
        if [ -z "$DEVICE_ID" ]; then
            echo "❌ Failed to create simulator"
            exit 1
        fi
        echo "Created simulator: $DEVICE_ID"
    fi
    
    # Save to config file
    echo "DEVICE_ID_FROM_USER_SETTINGS=$DEVICE_ID" > "$CONFIG_FILE"
    echo "Simulator ID saved to $CONFIG_FILE: $DEVICE_ID"
    echo "DEVICE_ID_FROM_USER_SETTINGS=$DEVICE_ID"
}

# Show usage if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [--clear-cache] [--help]"
    echo ""
    echo "Automatically finds or creates an iPhone 12 mini with iOS 16.4 for testing."
    echo "Caches the result to .stripe-ios-config for reuse."
    echo ""
    echo "Options:"
    echo "  --clear-cache    Clear the cached simulator ID"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Output:"
    echo "  Prints DEVICE_ID_FROM_USER_SETTINGS=<device_id> for use with 'source' command"
    exit 0
fi

main "$@"
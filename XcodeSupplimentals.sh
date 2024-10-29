#!/bin/bash

# Path to Xcode application
XCODE_PATH="/Applications/Xcode.app"

# Check if Xcode exists
if [ -d "$XCODE_PATH" ]; then
    echo "Xcode found, configuring..."

    # Select Xcode
    xcode-select -s "$XCODE_PATH"

    # Accept license
    xcodebuild -license accept

    # Install additional components
    xcodebuild -runFirstLaunch

    # Add everyone (every local account) to developer group
    dseditgroup -o edit -a everyone -t group _developer

    # Enable dev tools security
    DevToolsSecurity -enable

    echo "Xcode configuration complete."
else
    echo "Xcode not found."
fi

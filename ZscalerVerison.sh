#!/bin/bash

# Check if Zscaler is installed
if [[ -e "/Applications/Zscaler/Zscaler.app" ]]; then
    # Get version of Zscaler
    version=$(defaults read /Applications/Zscaler/Zscaler.app/Contents/Info.plist CFBundleShortVersionString)
    echo "<result>$version</result>"
else
    echo "<result>Not Installed</result>"
fi

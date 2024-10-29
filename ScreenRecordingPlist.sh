#!/bin/bash
 
# Get the current macOS version
os_version=$(sw_vers -productVersion)
echo "macOS version: $os_version"
 
# Check if the macOS version is 15.x or higher
if [[ "$os_version" =~ ^15\. ]]; then
echo "macOS version is 15.x or greater. Proceeding to find and read Screen Capture plist."
    # Read the Screen Capture plist file
    if [[ -f ~/Library/Group\ Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist ]]; then
        echo "Screen Capture plist exists. Reading..."
        plistresult=$(defaults read ~/Library/Group\ Containers/group.com.apple.replayd/ScreenCaptureApprovals.plist)
        echo "<result>$plistresult</result>"
    else
        echo "<result>Plist file not found</result>"
    fi
else
    echo "<result>Not on macOS Sequoia</result>"
fi
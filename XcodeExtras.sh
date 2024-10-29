#!/bin/bash

# Function to run commands and display their output
run_command() {
    echo "Running: $1"
    output=$(eval "$1" 2>&1)  # Capture both stdout and stderr
    echo "$output"  # Display the output
}

# Get the current logged-in user
CURRENT_USER=$(stat -f "%Su" /dev/console)

# Check if Xcode is selected
if xcode-select -p &> /dev/null; then
    echo "Xcode is already selected."
else
    run_command "xcode-select -s \"/Applications/Xcode.app\""
fi

# Check if Xcode license is accepted
if grep -q "accepted" ~/Library/Preferences/com.apple.dt.Xcode.plist; then
    echo "Xcode license is already accepted."
else
    run_command "xcodebuild -license accept"
fi

# Check for additional components installation
if [ -e "/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild" ]; then
    echo "Additional components are likely already installed."
else
    run_command "xcodebuild -runFirstLaunch"
fi

# Check if the _developer group exists
if dscl . -list /Groups | grep -q "_developer"; then
    # Check if the current user is already in the _developer group
    if id -Gn "$CURRENT_USER" | grep -q "_developer"; then
        echo "User '$CURRENT_USER' is already in the _developer group."
    else
        run_command "sudo dseditgroup -o edit -a \"$CURRENT_USER\" -t user _developer"
    fi
else
    run_command "sudo dseditgroup -o create _developer"  # Create group if it doesn't exist
    run_command "sudo dseditgroup -o edit -a \"$CURRENT_USER\" -t user _developer"
fi

# Enable dev tools security (if needed)
# if ! DevToolsSecurity -status | grep -q "enabled"; then
#     run_command "sudo DevToolsSecurity -enable"
# fi

echo "Script completed successfully."

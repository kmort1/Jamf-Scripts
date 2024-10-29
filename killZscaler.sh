#!/bin/bash

# Define the path to the uninstaller script
UNINSTALL_SCRIPT="/Applications/Zscaler/.Uninstaller.sh"

# Check if the uninstaller script exists
if [ -f "$UNINSTALL_SCRIPT" ]; then
    echo "Uninstaller script found. Proceeding with uninstallation."
    
    # Run the uninstaller script as root
    sudo sh "$UNINSTALL_SCRIPT"

    echo "Uninstallation command executed."
else
    echo "Uninstaller script not found. Exiting."
    exit 1
fi

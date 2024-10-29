#!/bin/bash

# Define the package path
PACKAGE_PATH="/Users/Shared/Management/Packages/Zscaler-osx-4.2.0.262-installer.pkg"

# Check if the package exists
if [ ! -f "$PACKAGE_PATH" ]; then
    echo "Package does not exist."
    exit 1
fi

# Define the path to the uninstaller script
UNINSTALL_SCRIPT="/Applications/Zscaler/.Uninstaller.sh"

# Check if the uninstaller script exists
if [ -f "$UNINSTALL_SCRIPT" ]; then
    echo "Uninstaller script found. Proceeding with uninstallation."
    
    # Run the uninstaller script as root
    sudo sh "$UNINSTALL_SCRIPT"
    if [ $? -ne 0 ]; then
        echo "Failed to execute the uninstaller script."
        exit 1
    fi

    echo "Uninstallation command executed."
else
    echo "Uninstaller script not found. Exiting."
    exit 1
fi

# Install the package
echo "Installing $PACKAGE_PATH..."
sudo installer -pkg "$PACKAGE_PATH" -target /
if [ $? -ne 0 ]; then
    echo "Failed to install package."
    exit 1
fi
echo "$PACKAGE_PATH installed successfully."

# Check for the folder and delete it if it exists
REVERT_ZCC_PATH="/Applications/Zscaler/RevertZcc"
if [ -d "$REVERT_ZCC_PATH" ]; then
    echo "Folder $REVERT_ZCC_PATH exists. Deleting it..."
    sudo rm -rf "$REVERT_ZCC_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to delete folder."
        exit 1
    fi
    echo "Folder deleted successfully."
else
    echo "Folder does not exist."
fi

# Run sudo jamf recon
echo "Running sudo jamf recon..."
sudo jamf recon
if [ $? -ne 0 ]; then
    echo "Failed to run sudo jamf recon."
    exit 1
fi
echo "sudo jamf recon completed successfully."

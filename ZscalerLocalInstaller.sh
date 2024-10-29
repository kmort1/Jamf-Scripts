#!/bin/bash

sleep 10

# Run sudo jamf recon
echo "Running sudo jamf recon..."
sudo jamf recon
if [ $? -ne 0 ]; then
    echo "Failed to run sudo jamf recon."
    exit 1
fi
echo "sudo jamf recon completed successfully."

# Define the package path
PACKAGE_PATH="/Users/Shared/Management/Packages/Zscaler-osx-4.2.0.262-installer.pkg"

# Check if the package exists
if [ ! -f "$PACKAGE_PATH" ]; then
    echo "Package $PACKAGE_PATH does not exist."
    exit 1
fi

# Install the package
echo "Installing $PACKAGE_PATH..."
sudo installer -pkg "$PACKAGE_PATH" -target /
if [ $? -ne 0 ]; then
    echo "Failed to install $PACKAGE_PATH."
    exit 1
fi
echo "$PACKAGE_PATH installed successfully."

echo "All packages installed successfully."

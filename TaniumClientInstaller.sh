#!/bin/bash

# Define the paths for the Tanium installation package and configuration file
PKG_PATH="/Users/Shared/Management/Files/Tanium/TaniumClient-7.4.9.1077-universal.pkg"
CONFIG_FILE_PATH="/Users/Shared/Management/Files/Tanium/tanium-init.dat"
TARGET_DIR="/Library/Tanium/TaniumClient"
VERBOSITY_LEVEL="1"

# Start the Tanium Client installation
echo "Starting Tanium Client installation..."
sudo installer -pkg "$PKG_PATH" -target /
if [ $? -ne 0 ]; then
    echo "Error: Tanium Client installation failed."
    exit 1
fi
echo "Tanium Client installation completed successfully."

# Wait for 5 seconds to ensure the installation is fully processed
echo "Sleeping for 5 seconds..."
sleep 5

# Configure the Tanium Client with verbosity level set to 1
echo "Setting Tanium Client log verbosity level to $VERBOSITY_LEVEL..."
sudo /Library/Tanium/TaniumClient/TaniumClient config set LogVerbosityLevel $VERBOSITY_LEVEL
if [ $? -ne 0 ]; then
    echo "Error: Failed to set log verbosity level."
    exit 1
fi
echo "Log verbosity level set to $VERBOSITY_LEVEL successfully."

# Copy the configuration file to the Tanium Client directory
echo "Copying configuration file to Tanium Client directory..."
sudo cp "$CONFIG_FILE_PATH" "$TARGET_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy configuration file."
    exit 1
fi
echo "Configuration file copied successfully."

echo "Tanium Client setup completed."
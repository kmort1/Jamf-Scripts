#!/bin/bash

# Define the file path
file_path="/Library/Preferences/org.800-53r5*"

# Check if the file exists
if ls $file_path 1> /dev/null 2>&1; then
    # Delete the file
    sudo rm -f $file_path
    echo "File '$file_path' deleted."
else
    echo "File '$file_path' not found. Exiting."
    exit 0
fi
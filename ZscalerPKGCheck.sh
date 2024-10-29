#!/bin/bash

# Define the directory to search for Zscaler files
DIRECTORY="/Users/Shared/Management/Packages"

# Search for any files containing "zscaler" in their name within the directory
FOUND_FILE=$(find "$DIRECTORY" -type f -iname "*zscaler*" | head -n 1)

# Check if any such file was found
if [ -n "$FOUND_FILE" ]; then
    echo "<result>PKG Exists</result>"
else
    echo "<result>PKG Does Not Exist</result>"
fi

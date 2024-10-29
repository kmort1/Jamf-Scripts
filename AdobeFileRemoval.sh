#!/bin/bash

# Define an array of paths to clean
paths=(
    "/Library/Application Support/Adobe"
    "/Library/Logs/Adobe"
    "/Library/PDF Services/Save as Adobe PDF"
    "/Library/LaunchAgents/com.adobe*"
    "/Library/LaunchDaemons/com.adobe*"
    "$HOME/Library/Application Support/Adobe"
    "$HOME/Library/Logs/Adobe"
    "$HOME/Library/Logs/CreativeCloud"
    "$HOME/Library/Logs/NGL"
    "$HOME/Library/Logs/oobelib.log"
    "$HOME/Library/Logs/PDApp.log"
    "$HOME/Library/Logs/acroNGLLog.txt"
    "$HOME/Library/Logs/AdobeVulcan"
    "$HOME/Library/Logs/CSXS"
)

# Function to remove files and directories
remove_files() {
    local path="$1"
    
    if [ -e "$path" ]; then
        rm -rf "$path"
        echo "Removed: $path"
    else
        echo "Not found: $path"
    fi
}

# Loop through each path and remove it
for path in "${paths[@]}"; do
    remove_files "$path"
done

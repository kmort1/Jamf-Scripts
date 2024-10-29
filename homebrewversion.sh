#!/bin/bash

# Check if Homebrew is installed and get the version using root
brew_path=$(sudo -i -u $(ls -l /dev/console | awk '{print $3}') which brew 2>/dev/null)

if [ -x "$brew_path" ]; then
    brew_version=$(sudo -i -u $(ls -l /dev/console | awk '{print $3}') brew --version | head -n 1 | awk '{print $2}')
    echo "<result>$brew_version</result>"
else
    echo "<result>Not Installed</result>"
fi

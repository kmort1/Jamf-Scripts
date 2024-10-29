#!/bin/bash

# Get the current logged-in user
CURRENT_USER=$(stat -f "%Su" /dev/console)

# Check if the _developer group exists
if dscl . -list /Groups | grep -q "_developer"; then
    # Check if the current user is in the _developer group
    if id -Gn "$CURRENT_USER" | grep -q "_developer"; then
        echo "<result>Yes</result>"
    else
        echo "<result>No</result>"
    fi
else
    echo "<result>No</result>"
fi

#!/bin/bash

# Get the current logged-in user
loggedInUser=$(stat -f "%Su" /dev/console)
echo "$loggedInUser"

# Check if the logged-in user is found
if [ -z "$loggedInUser" ]; then
    echo "<result>No user found</result>"
    exit 1
fi

# Get SecureToken status for the logged-in user
status=$(sudo sc_auth filevault -o status -u "$loggedInUser" 2>&1)

# Check and parse the status output
if echo "$status" | grep -q "SecureToken for user $loggedInUser is needed and is present as"; then
    # Extract the hash value
    hashValue=$(echo "$status" | awk -F 'as ' '{print $2}')
    echo "<result>Mapped</result>"
elif echo "$status" | grep -q "SecureToken for user $loggedInUser is needed and is not present"; then
    echo "<result>Not Mapped</result>"
else
    echo "<result>Unknown Status</result>"
fi

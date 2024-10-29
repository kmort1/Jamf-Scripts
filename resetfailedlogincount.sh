#!/bin/bash

# Get the currently logged in user
currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

# Check if the currentUser variable is not empty
if [ -z "$currentUser" ]; then
    echo "Unable to determine the current user"
    exit 1
fi

# Get the failed login count for the current user
failedLoginCount=$(/usr/bin/dscl . readpl "/Users/$currentUser" accountPolicyData failedLoginCount | awk '{print $2}')

# Check if failedLoginCount was retrieved successfully
if [ -z "$failedLoginCount" ]; then
    echo "Unable to retrieve failed login count"
    exit 1
fi

# If failed login count is greater than 0, reset it to 0
if [ "$failedLoginCount" -gt 0 ]; then
    /usr/bin/dscl . deletepl "/Users/$currentUser" accountPolicyData failedLoginCount
    echo "Failed login count was reset to 0"
else
    echo "Failed login count is already 0"
fi

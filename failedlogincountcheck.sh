#!/bin/bash

# Get the currently logged in user
currentUser=$(/usr/bin/stat -f "%Su" /dev/console)

# Check if the currentUser variable is not empty
if [ -z "$currentUser" ]; then
    echo "<result>Unable to determine current user</result>"
    exit 1
fi

# Get the failed login count for the current user
failedLoginCount=$(/usr/bin/dscl . readpl "/Users/$currentUser" accountPolicyData failedLoginCount | awk '{print $2}')

# Check if failedLoginCount was retrieved successfully
if [ -z "$failedLoginCount" ]; then
    echo "<result>Unable to retrieve failed login count</result>"
    exit 1
fi

# Output the failed login count
if [ "$failedLoginCount" -eq 0 ]; then
    echo "<result>0</result>"
else
    echo "<result>$failedLoginCount</result>"
fi

#!/bin/bash

# Get the currently logged-in user
loggedInUser=$(stat -f "%Su" /dev/console)

# Check if the FVTokenSecret exists for the logged-in user
fvTokenSecret=$(dscl . read /Users/"$loggedInUser" FVTokenSecret 2>&1)

# Determine the result based on the FVTokenSecret output
if echo "$fvTokenSecret" | grep -q "No such key: FVTokenSecret"; then
    result="No FVTokenSecret"
elif echo "$fvTokenSecret" | grep -q "dsAttrTypeNative:FVTokenSecret:"; then
    result="FVTokenSecret present"
else
    result="Unknown"
fi

# Output the result
echo "<result>$result</result>"

#!/bin/bash

# Define the path to the XML file
XML_FILE="/Users/Shared/Management/Files/AccountInactivity.xml"

# Check if the XML file exists
if [[ ! -f "$XML_FILE" ]]; then
    echo "Error: XML file not found at $XML_FILE"
    exit 1
fi

# Set the pwpolicy using the XML file
/usr/bin/pwpolicy setaccountpolicy "$XML_FILE"
RESULT=$?

# Check if the command was successful
if [[ $RESULT -ne 0 ]]; then
    echo "Error: Failed to set pwpolicy. Exit code: $RESULT"
    exit $RESULT
else
    echo "Success: pwpolicy set successfully using $XML_FILE"
fi

# Verify the policy
VERIFICATION=$(/usr/bin/pwpolicy -getaccountpolicies)
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to retrieve pwpolicy. Exit code: $?"
    exit 1
fi

# Output the current policies for verification
echo "Current pwpolicy settings:"
echo "$VERIFICATION"

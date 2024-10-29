#!/bin/bash

# Define the current user
currentuser=$(/usr/bin/stat -f "%Su" /dev/console)

# Get the XML data from dscl command
plist_data=$(/usr/bin/dscl . read /Users/"$currentuser" accountPolicyData)

# Extract the XML portion from the dscl output
# Note: The XML starts after 'accountPolicyData:' and ends before the next line of the output
plist_content=$(echo "$plist_data" | sed -n '/<?xml/,/<\/plist>/p' | sed -e '1d' -e '$d')

# Extract the failedLoginCount value using grep and awk
failed_login_count=$(echo "$plist_content" | grep -A1 '<key>failedLoginCount</key>' | awk '/<integer>/{print $1}' | sed 's/<integer>//' | sed 's/<\/integer>//')

# Output the result for Jamf
echo "<result>$failed_login_count</result>"

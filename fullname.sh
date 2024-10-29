#!/bin/bash

# Get the email address
email=$(defaults read /Users/localadmin/Library/Preferences/com.microsoft.office.plist | awk '/OfficeActivationEmailAddress/ {print $3}' | tr -d '";')

# Extract first and last name from email address
firstname=$(echo "$email" | cut -d'.' -f1)
lastname=$(echo "$email" | cut -d'.' -f2 | cut -d'@' -f1)

# Capitalize first letter of first and last name
capitalized_firstname=$(echo "$firstname" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
capitalized_lastname=$(echo "$lastname" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

# Concatenate capitalized first and last name
fullname="$capitalized_firstname $capitalized_lastname"

echo $fullname

# Run jamf recon with the obtained full name
/usr/local/bin/jamf recon -endUsername "$fullname"


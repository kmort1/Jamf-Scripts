#!/bin/bash

# Get the email address
email=$(defaults read /Users/localadmin/Library/Preferences/com.microsoft.office.plist | awk '/OfficeActivationEmailAddress/ {print $3}' | tr -d '";')
echo $email

# Run jamf recon with the obtained email address
echo "Uploading email to Jamf"
sudo /usr/local/bin/jamf recon -email "$email"

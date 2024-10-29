#!/bin/bash

# Jamf Pro URL
jamfProURL="https://mdm2.dhs.gov:8443"
# API Client
jamfAPIUser="c99247ad-4f83-4f42-8c02-f8f94b550762"
# API Password
jamfAPIPassword="cEqjqO7sPgSaNqnVP0zCKObS5kuaECHPpwSQjqG595N_QURoGhVn3kHOQKAVSlAM"
# Computer Serial Number
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
# Output XML
outputXML="/Users/Shared/Management/Files/jamfEmail.xml"

# Get the current logged-in user
loggedInUser=$(stat -f "%Su" /dev/console)
echo $loggedInUser

# Get the email address
email=$(defaults read /Users/"$loggedInUser"/Library/Preferences/com.microsoft.office.plist | awk '/OfficeActivationEmailAddress/ {print $3}' | tr -d '";')
echo $email

# Create XML
xmlData="<computer><location><email_address>$email</email_address></location></computer>"

# Store XML
echo "$xmlData" > "$outputXML"

# # Send XML to Jamf Server
# emaildata=$(curl -s --request PUT \
#     --url "${jamfProURL}/JSSResource/computers/serialnumber/${serialnumber}" \
#     --user "${jamfAPIUser}:${jamfAPIPassword}" \
#     --header "Content-Type: application/xml" \
#     --data "${xmlData}")

# if [[ "$emaildata" == *"<email_address>${email}</email_address>"* ]]; then
#     echo "Email successfuly uploaded"
# else
#     echo "Failed to upload"
# fi
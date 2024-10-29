#!/bin/bash

# Terminate Kerberos SSO-Extension processes
echo "Terminating KerberosExtension, AppSSOAgent, and KerberosMenuExtra..."
pkill -9 KerberosExtension AppSSOAgent KerberosMenuExtra

# Check if the termination was successful
if [ $? -eq 0 ]; then
    echo "Processes terminated successfully."
else
    echo "Failed to terminate some processes."
fi

# Fetch the Kerberos SSO-Extension RELM ID
echo "Resetting Kerberos SSO-Extension..."
APP_SSO_JO=$( /usr/bin/app-sso -l -j )
if [ $? -eq 0 ]; then
    # Extract the RELM ID from the JSON output
    APP_SSO_ID=$(echo "$APP_SSO_JO" | awk -F'"' '{$0=$2}NF')
    
    # Reset Kerberos SSO-Extension with RELM ID
    /usr/bin/app-sso -d "$APP_SSO_ID"
    echo "Reset Kerberos SSO-Extension with RELM ID: $APP_SSO_ID"
else
    echo "Failed to retrieve Kerberos SSO information."
fi

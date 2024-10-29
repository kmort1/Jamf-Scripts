#!/bin/bash

# Get the current logged in user
current_user=$(stat -f "%Su" /dev/console)

# Run the commands
sudo sc_auth unpair -u "$current_user"
sudo dscl . delete /Users/"$current_user" AltSecurityIdentities

# Echo message
echo "Smartcard unpaired"

# Exit with status code 0
exit 0

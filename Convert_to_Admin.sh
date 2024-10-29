#!/bin/bash

# Get the current logged in user
current_user=$(stat -f "%Su" /dev/console)

# Check if the current user is in the admin group
if id -nG "$current_user" | grep -qw "admin"; then
    echo "Current user is already in the admin group."
else
    # Add the current user to the admin group
    sudo dseditgroup -o edit -a "$current_user" -t user admin
    echo "Current user added to the admin group."
fi
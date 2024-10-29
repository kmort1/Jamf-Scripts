#!/bin/zsh

# Determine the currently logged-in user
console_user=$(/usr/bin/stat -f "%Su" /dev/console)

# Check if the current user is an admin
adminCheck=$(dseditgroup -o checkmember -m "$console_user" admin)

# Display the current role
if [[ $adminCheck == "no $console_user is NOT a member of admin" ]]; then
    echo "The user '$console_user' is already a standard user."
    exit 0
elif [[ $adminCheck == "yes $console_user is a member of admin" ]]; then
    echo "The user '$console_user' is an admin. Proceeding to change to a standard user..."

    # Remove the user from the admin group
    sudo dseditgroup -o edit -d "$console_user" -t user admin

    if [ $? -eq 0 ]; then
        echo "Successfully changed '$console_user' to a standard user."
    else
        echo "Failed to change '$console_user' to a standard user."
        exit 1
    fi
else
    echo "Unable to determine the user role."
    exit 1
fi

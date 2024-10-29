#!/bin/bash

# Function to run commands and display their output
run_command() {
    echo "Running: $1"
    output=$(eval "$1" 2>&1)  # Capture both stdout and stderr
    echo "$output"  # Display the output
}

# Get the current logged-in user
CURRENT_USER=$(stat -f "%Su" /dev/console)

# Check if the _developer group exists
if dscl . -list /Groups | grep -q "_developer"; then
    # Check if the current user is already in the _developer group
    if id -Gn "$CURRENT_USER" | grep -q "_developer"; then
        echo "User '$CURRENT_USER' is already in the _developer group."
    else
        run_command "sudo dseditgroup -o edit -a \"$CURRENT_USER\" -t user _developer"
    fi
else
    run_command "sudo dseditgroup -o create _developer"  # Create group if it doesn't exist
    run_command "sudo dseditgroup -o edit -a \"$CURRENT_USER\" -t user _developer"
fi
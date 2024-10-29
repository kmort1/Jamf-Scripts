#!/bin/bash

# IBM Notifier binary paths
NA_PATH="/Applications/IBM Notifier.app/Contents/MacOS/IBM Notifier"

# Variables for the popup notification for ease of customization
WINDOWTYPE="popup"
BAR_TITLE="My Organization's Notification"
TITLE="Enter App Specific Title Here"
TIMEOUT="" # leave empty for no notification time
BUTTON_1="OK"
BUTTON_2="Cancel"
SUBTITLE="Enter popup information here. \n\nThis can be whatever you want."

### FUNCTIONS ###

prompt_user() {
    # This will call the IBM Notifier Agent
    # USAGE: prompt_user "1" for two buttons, otherwise just the function for one
    if [[ "${#1}" -ge 1 ]]; then
        sec_button=("-secondary_button_label" "${BUTTON_2}")
    fi

    button=$("${NA_PATH}" \
        -type "${WINDOWTYPE}" \
        -bar_title "${BAR_TITLE}" \
        -title "${TITLE}" \
        -subtitle "${SUBTITLE}" \
        -timeout "${TIMEOUT}" \
        -main_button_label "${BUTTON_1}" \
        "${sec_button[@]}" \
        -always_on_top)

    echo "$?"
}

### END FUNCTIONS ###

# Function to prompt user with an input field
prompt_user_with_input() {
    input=$(osascript -e 'Tell application "System Events" to display dialog "Enter your input:" default answer ""' -e 'text returned of result' 2>/dev/null)
    echo "$input"
}

# Example 1 button prompt
RESPONSE=$(prompt_user)
echo "$RESPONSE"

# Example 2 button prompt
RESPONSE=$(prompt_user "1")
echo "$RESPONSE"

# Example with input field
INPUT=$(prompt_user_with_input)
echo "User input: $INPUT"

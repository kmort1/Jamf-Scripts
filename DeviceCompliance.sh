#!/bin/bash

# Define variables
IBM_NOTIFIER="/Applications/Utilities/IBM Notifier.app/Contents/MacOS/IBM Notifier"
BAR_TITLE="Device Compliance Required"
TITLE="Device Compliance"
SUBTITLE="macOS Device Compliance is required to ensure that you have access to esstential apps (i.e., MS365). Please click “OK” to be directed to Self Service to run Device Compliance"
ICON_PATH="https://ics.services.jamfcloud.com/icon/hash_48269aa18ea19fab93833f0fc512042cd7bae9ee610e8e82d68e82b0293a672c"
MAIN_BUTTON_LABEL="OK"
MAIN_BUTTON_CTA_TYPE="link"
MAIN_BUTTON_CTA_PAYLOAD="jamfselfservice://content?entity=policy&id=204&action=view"
SECONDARY_BUTTON_LABEL="Cancel"
HELP_BUTTON_CTA_TYPE="infopopup"
HELP_BUTTON_CTA_PAYLOAD="If you have any questions/issues please put in a ticket with IT4Me"

# Execute the command
"$IBM_NOTIFIER" -type popup \
-bar_title "$BAR_TITLE" \
-title "$TITLE" \
-subtitle "$SUBTITLE" \
-icon_path "$ICON_PATH" \
-icon_width 100 \
-icon_height 100 \
-main_button_label "$MAIN_BUTTON_LABEL" \
-main_button_cta_type "$MAIN_BUTTON_CTA_TYPE" \
-main_button_cta_payload "$MAIN_BUTTON_CTA_PAYLOAD" \
-secondary_button_label "$SECONDARY_BUTTON_LABEL" \
-help_button_cta_type "$HELP_BUTTON_CTA_TYPE" \
-help_button_cta_payload "$HELP_BUTTON_CTA_PAYLOAD" \
-position bottom_right \
-hide_title_bar \
-silent \
-always_on_top \
-timeout 300 \
-unmovable

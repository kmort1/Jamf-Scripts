#!/bin/bash

# Get USB devices information using system_profiler
usb_devices_info=$(system_profiler SPUSBDataType)

# Parse the USB devices information
parse_usb_devices() {
    echo "$1" | awk -F': ' '
    BEGIN {
        in_device = 0
        indent_level = 0
        device_details = ""
    }
    {
        # Determine the level of indentation
        indent_level = length($1) - length(gensub(/^ +/, "", "g", $1))

        # If the line starts with a non-space character, it's a new device section
        if (indent_level == 0) {
            if (in_device) {
                print device_details "\n"
                device_details = ""
            }
            device_details = $0
            in_device = 1
        } else if (indent_level > 0 && indent_level % 4 == 0) {
            gsub(/^ +/, "", $0)
            device_details = device_details "\n" $0
        }
    }
    END {
        if (in_device) {
            print device_details
        }


# Call the parse_usb_devices function and store the result
usb_devices=$(parse_usb_devices "$usb_devices_info")

# Output the result in XML format for Jamf Pro
echo "<result>"
echo "$usb_devices"
echo "</result>"

exit 0

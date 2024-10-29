#!/bin/bash

# Extension Attribute script to obtain location data on macOS
# Check for macOS version
os_version=$(sw_vers -productVersion | awk -F. '{print $1 "." $2}')
required_os="14.0"

if [[ "$os_version" < "$required_os" ]]; then
    echo "<result>Requires macOS 14 or later</result>"
    exit 0
fi

# AppleScript to request location access if not already granted
osascript -e 'tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
    display dialog "This script requires location access. Please go to System Preferences > Security & Privacy > Location Services and allow location access for Terminal." buttons {"OK"} default button 1
end tell'

# Function to obtain location data using CoreLocation framework
get_location() {
    # Using Python to get the location data
    location=$(python3 - << 'EOF'
import CoreLocation
import time

location_manager = CoreLocation.CLLocationManager.alloc().init()
location_manager.setDelegate_(None)
location_manager.requestWhenInUseAuthorization()
location_manager.startUpdatingLocation()

time.sleep(5)  # Wait for location update

location = location_manager.location()
if location:
    latitude = location.coordinate().latitude
    longitude = location.coordinate().longitude
    print(f"{latitude},{longitude}")
else:
    print("Location not available")
EOF
    )

    echo "$location"
}

# Check if location services are enabled and get location
location_status=$(defaults read /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled 2>/dev/null)
if [[ "$location_status" == "1" ]]; then
    location=$(get_location)
    if [[ "$location" != "Location not available" ]]; then
        echo "<result>$location</result>"
    else
        echo "<result>Location not available</result>"
    fi
else
    echo "<result>Location services are disabled</result>"
fi

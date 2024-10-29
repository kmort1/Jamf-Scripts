#!/bin/bash

# Parameters for jamfHelper window
ImageFilePath="/Users/Shared/Management/Images/DHS.png"
currentUser=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
windowType="utility"
windowTitle="Department of Homeland Security"
description="Successfully Paired Smart Card!

To complete pairing, a log out must be performed. Please keep the Smartcard plugged in and click 'Log Out' or you will automatically be logged out. 

Once logged out, please type in your PIN and macOS Keychain password."
buttonText="Log Out"
iconPath="$ImageFilePath"
timeout=90
countdownAlign="right"
descriptionAlign="left"
windowWidth=300
windowHeight=100

# Function to display countdown with jamfHelper
display_countdown() {
  local countdown=$1
  local title=$2
  local description=$3
  local icon=$4
  local width=$5
  local height=$6

  while [ $countdown -gt 0 ]; do
    # Display jamfHelper window with countdown
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
      -windowType "$windowType" \
      -title "$title" \
      -description "$description" \
      -icon "$icon" \
      -button1 "$buttonText" \
      -timeout $timeout \
      -countdown -countdownPrompt "You will be automatically logged out in " \
      -alignCountdown "$countdownAlign" \
      -alignDescription "$descriptionAlign" \
      -windowPosition center \
      -windowWidth $width \
      -windowHeight $height \

    # Check if the user clicked the "Log Out" button
    if [ $? -eq 0 ]; then
      echo "User chose to Log Out"
      # Perform logout actions here
      /bin/launchctl bootout gui/$(id -u $currentUser)
      exit 0
    fi

    # Decrement countdown
    countdown=$((countdown - $timeout))

    # Sleep for the specified timeout
    sleep 90
  done

  # Countdown finished, perform actions here if needed
  echo "Countdown finished. Logging out the user."
  /bin/launchctl bootout gui/$(id -u $currentUser)
}

# Display the combined message and start the countdown
display_countdown 90 "$windowTitle" "$description" "$iconPath" $windowWidth $windowHeight &

#!/bin/bash

# Get the serial number of the the Mac
serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

#Prepend "DHS" to the serial number
new_hostname="DSH$serial"

# Set new hostname
sudo scutil --set Hostname "$new_hostname"
sudo scutil --set ComputerName "$new_hostname"
sudo scutil --set LocalHostname "$new_hostname"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$new_hostname"


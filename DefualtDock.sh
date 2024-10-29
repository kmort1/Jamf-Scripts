#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# 
# version 2.0
# Written by: Mischa van der Bent
#
# Permission is granted to use this code in any way you want.
# Credit would be nice, but not obligatory.
# Provided "as is", without warranty of any kind, express or implied.
#
# DESCRIPTION
# This script configures users docks using docktutil
# source dockutil https://github.com/kcrawford/dockutil/
# 
# REQUIREMENTS
# dockutil Version 3.0.0 or higher installed to /usr/local/bin/
# Compatible with macOS 11.x and higher
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# COLLECT IMPORTANT USER INFORMATION
# Get the currently logged in user
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

# Get uid logged in user
uid=$(id -u "${currentUser}")

# Current User home folder - do it this way in case the folder isn't in /Users
userHome=$(dscl . -read /users/${currentUser} NFSHomeDirectory | cut -d " " -f 2)

# Path to plist
plist="${userHome}/Library/Preferences/com.apple.dock.plist"

jss_url=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)

# Convenience function to run a command as the current user
# usage: runAsUser command arguments...
runAsUser() {  
	if [[ "${currentUser}" != "loginwindow" ]]; then
		launchctl asuser "$uid" sudo -u "${currentUser}" "$@"
	else
		echo "no user logged in"
		exit 1
	fi
}

# # Check if dockutil is installed
# if [[ -x "/usr/bin/dockutil" ]]; then
#     dockutil="/usr/bin/dockutil"
# else
#     echo "dockutil not installed in /usr/bin, exiting"
#     exit 1
# fi

# get dockutil if not present 

if [[ ! -e "/usr/local/bin/dockutil" ]]; then
        if [[ -z $jss_url ]]; then
	curl --output-dir /private/tmp -O https://github.com/kcrawford/dockutil/releases/download/3.1.3/dockutil-3.1.3.pkg ;
	installer -pkg /private/tmp/dockutil-3.1.3.pkg -target / ;
	sleep 1 ;
fi
   /usr/local/bin/jamf policy -event install-dockutil
fi

# Check if dockutil is installed
if [[ -x "/usr/local/bin/dockutil" ]]; then
    dockutil="/usr/local/bin/dockutil"
else
    echo "dockutil not installed in /usr/bin, exiting"
    exit 1
fi

# Version dockutil
dockutilVersion=$(${dockutil} --version)
echo "Dockutil version = ${dockutilVersion}"

# Create a clean Dock
runAsUser "${dockutil}" --remove all --no-restart ${plist}
echo "clean-out the Dock"

# Full path to Applications to add to the Dock
apps=(
"/System/Applications/Launchpad.app"
"/System/Applications/System Settings.app"
"/System/Applications/Maps.app"
"/System/Applications/News.app"
"/Applications/Adobe Acrobat DC/Adobe Acrobat.app"
"/Applications/Microsoft Edge.app"
"/Applications/Safari.app"
"/Applications/Microsoft Outlook.app"
"/Applications/Microsoft Teams.app"
"/Applications/Microsoft Word.app"
"/Applications/Microsoft Excel.app"
"/Applications/Microsoft PowerPoint.app"
"/Applications/Microsoft OneNote.app"
"/Applications/Self Service.app"
)

# Loop through Apps and check if App is installed, If Installed at App to the Dock.
for app in "${apps[@]}"; 
do
	if [[ -e ${app} ]]; then
		runAsUser "${dockutil}" --add "$app" --no-restart ${plist};
	else
		echo "${app} not installed"
    fi
done

runAsUser "${dockutil}" --move 'System Settings' --position end
runAsUser "${dockutil}" --move 'Self Service' --position end

# Add Application Folder to the Dock
# runAsUser "${dockutil}" --add /Applications --view grid --display folder --sort name --no-restart ${plist}

# Add logged in users Downloads folder to the Dock
runAsUser "${dockutil}" --add ${userHome}/Downloads --view fan --display stack --sort dateadded --no-restart ${plist}

# Disable show recent
runAsUser defaults write com.apple.dock show-recents -bool FALSE
echo "Hide show recent from the Dock"

# # Minimize to app
# runAsUser defaults write com.apple.dock minimize-to-application -bool true

# runAsUser defaults write com.apple.dock autohide-delay -float 0
# runAsUser defaults write com.apple.dock autohide-time-modifier -int 0

# sleep 3

# Kill dock to use new settings
killall -KILL Dock
echo "Restarted the Dock"

echo "Finished creating default Dock"

exit 0
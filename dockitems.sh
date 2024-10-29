#!/bin/bash

## This allows you to specify lists of items to remove and add in arrays, and then they'll be done in bulk using a for loop
## Items to remove should be the label (usually the name of the application)
## Items to add are the full path to the item to add (usually /Applications/NAMEOFAPP.app)
## A few examples are prepopulated in the arrays, but feel free to tweak as suits the needs of your organization

# original https://raw.githubusercontent.com/aysiu/Mac-Scripts-and-Profiles/master/DockutilAddRemoveArrays.sh
# bash string manipulations here https://www.tldp.org/LDP/LG/issue18/bash.html

# TO-DO: 
# ✅ check for jamf
# ✅ check for dockutil; install from jamf (or download from site)
# ✅ check for AD binding, add Directory Utility if bound
# ✅ validate new AD, ARD vs SS checks, & that add to array works as intended
# ✅ check OS version, add System Prefs vs System Settings

# if dockutil is present, bail out
# if dockutil is not present, read jss and try jamf policy first
# if jss is empty OR if jss not empty BUT dockutil still not present, try direct download
# if dockutil still not present, bail out

# variables

currentUser=$(stat -f %Su "/dev/console") # pete
currentHomeFolder=$(dscl . read "/Users/$currentUser" NFSHomeDirectory | awk '{ print $NF }') # /Users/pete
uid=$(id -u "$currentUser") # 501

jss_url=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)

# run as user since Jamf runs scripts by default, and we're poking userspace

runAsUser() {  
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
    # uncomment the exit command to make the function exit with an error when no user is logged in
    # exit 1
  fi
} 

# get dockutil if not present 

if [[ ! -e "/usr/local/bin/dockutil" ]]; then
        if [[ -z $jss_url ]]; then
	curl --output-dir /private/tmp -O https://github.com/kcrawford/dockutil/releases/download/3.1.3/dockutil-3.1.3.pkg ;
	installer -pkg /private/tmp/dockutil-3.1.3.pkg -target / ;
	sleep 1 ;
fi
   /usr/local/bin/jamf policy -event install-dockutil
fi

itemsToRemove=(
   "Address Book"
   "Books"
   "Calculator"
   "Calendar"
   "Clock"
   "Contacts"
   "Dictionary"
   "FaceTime"
   "Find My"
   "Font Book"
   "Freeform"
   "iBooks"
   "Image Capture"
   "iMovie"
   "iPhoto"
   "iTunes"
   "Keynote"
   "Launchpad"
   "Mail"
   "Maps"
   "Messages"
   "Mission Control"
   "Notes"
   "Numbers"
   "Pages"
   "Photos"
   "Podcasts"
   "QuickTime"
   "QuickTime Player"
   "Siri"
   "Shortcuts"
   "Stickies"
   "Stocks"
   "TextEdit"
   "Time Machine"
   "TV"
   "Voice Memos"
   "Weather"
)

itemsToAdd=(
   "/Applications/Google Chrome.app"
   "/Applications/Safari.app"
   "/Applications/Utilities/Terminal.app"
)  


# check OS version, add correct System Settings vs Preferences

macOSversionMAJOR=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F. '{ print $1}')

if [[ $macOSversionMAJOR == "13" || $macOSversionMAJOR == "14" ]]; then
    itemsToAdd+=("/Applications/System Settings.app")
else
    itemsToAdd+=("/Applications/System Preferences.app")
fi    


for removalItem in "${itemsToRemove[@]}"
   do
      # Check that the item is actually in the Dock
      inDock=$(/usr/local/bin/dockutil --list "${currentHomeFolder}" | /usr/bin/grep "$removalItem")
      if [ -n "$inDock" ]; then
         /usr/local/bin/dockutil --remove "$removalItem" "${currentHomeFolder}" --no-restart
      fi
   done


for additionItem in "${itemsToAdd[@]}"
   do
      # Check that the item actually exists to be added to the Dock and that it isn't already in the Dock
      # Stripping path and extension code based on code from http://stackoverflow.com/a/2664746
      additionItemString=${additionItem##*/}
      additionItemBasename=${additionItemString%.*}
      inDock=$(/usr/local/bin/dockutil --list "${currentHomeFolder}" | /usr/bin/grep "$additionItemBasename")
      if [ -e "$additionItem" ] && [ -z "$inDock" ]; then
            /usr/local/bin/dockutil --add "$additionItem" "${currentHomeFolder}" --no-restart
      fi
   done

sleep 3

/usr/bin/killall Dock
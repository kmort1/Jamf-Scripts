# All Applications to disable Sonoma reactions for
allApps=(
    "videoeffects/us-zoom-xos/reactions-enabled"
    "videoeffects/us-zoom-xos/gestures-enabled"
    "videoeffects/com-microsoft-teams/gestures-enabled"
    "videoeffects/com-microsoft-teams/reactions-enabled"
    "videoeffects/com-microsoft-teams-helper/reactions-enabled"
    "videoeffects/com-apple-QuickTimePlayerX/gestures-enabled"
    "videoeffects/com-apple-systempreferences/reactions-enabled"
    "videoeffects/com-apple-controlcenter/reactions-enabled"
    "videoeffects/com-apple-cmio-ContinuityCaptureAgent/reactions-enabled"
    "videoeffects/com-apple-Safari/reactions-enabled"
    "videoeffects/com-apple-QuickTimePlayerX/reactions-enabled"
    "videoeffects/com-apple-FaceTime/reactions-enabled"
    "videoeffects/com-apple-Safari/reactions-enabled"
    "videoeffects/com-microsoft-teams2/reactions-enabled"
    "videoeffects/com-microsoft-teams2/gestures-enabled")

#plist location to edit
plist="Library/Group Containers/group.com.apple.secure-control-center-preferences/Library/Preferences/group.com.apple.secure-control-center-preferences.av.plist"

# For each local user disable Sonoma reactions for all specified applications
localUsers=$( dscl . list /Users UniqueID | awk '$2 >= 501 {print $1}' | grep -v admin )
echo "$localUsers" | while read user; do
    user=`stat -f "%Su" /dev/console`
    echo "User: $user"

    for domain in "${allApps[@]}"; do
        result=$(sudo /usr/libexec/PlistBuddy -c "Set $domain false" "/Users/$user/$plist" 2>&1)
        echo "$domain"
        
        if [[ "$result" == *"Does Not Exist"* ]]; then
            echo "Adding $domain to false"
            
            /usr/libexec/PlistBuddy -c "Add $domain bool false" "/Users/$user/$plist"
        elif [[ "$result" == *"Error"* ]]; then
            echo "An error occurred: $result"
        else
            echo "Setting $domain to false"
        fi
    done
done

#User Default Template
for domain in "${allApps[@]}"; do
    /usr/libexec/PlistBuddy -c "Add $domain bool false" "/System/Library/User Template/English.lproj/$plist"
done
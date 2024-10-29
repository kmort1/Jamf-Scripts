#!/bin/zsh

# Smartcard Attribute Mapping for Local Accounts 

# Variables:
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
dsEditGroup="/usr/sbin/dseditgroup"
dscl="/usr/bin/dscl"
arch=$(/usr/bin/arch)
piv_path=""
tmpdir=""
defaults="/usr/bin/defaults"
logFile="/var/tmp/smartcard_pairing.log"

# The body of the message that will be displayed once 1 attempt is left on the Smartcard.
FORGOT_PIN_MESSAGE="Your Message Here"

# Company logo. (Tested with PNG, JPG, GIF, PDF, and AI formats.)
LOGO="/System/Library/Frameworks/CryptoTokenKit.framework/ctkbind.app/Contents/Resources/AppIcon.icns"

# Title of the message to be displayed to the user
PROMPT_TITLE=""

# Convert POSIX path of logo icon to Mac path for AppleScript
LOGO_POSIX="$(/usr/bin/osascript -e 'tell application "System Events" to return POSIX file "'"$LOGO"'" as text')"

# Check for logged in user.
currentUser="$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )"

# Check for pairing
checkForPaired (){
  tokenCheck=$(/usr/bin/dscl . read /Users/"$currentUser" AuthenticationAuthority | grep -c tokenidentity)
    if [[ "$tokenCheck" > 0 ]]; then
      echo "Unpair $currentUser"
      /usr/sbin/sc_auth unpair -u "$currentUser"
    else
      echo "Nothing Paired"
    fi
}

# Prompt the user to insert card, once inserted prompt will go away.
prompt (){
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" \
-windowType utility -title "Smartcard Mapping" -description "Please insert your smartcard to begin." \
-alignDescription center -lockHUD & while [[ $( security list-smartcards 2>/dev/null \
| grep -c com.apple.pivtoken ) -lt 1 ]]; do sleep 1; done; kill -9 $!
}

getUPN(){
# Create temporary directory to export certs:
tmpdir=$(/usr/bin/mktemp -d)

# Export certs on smartcard to temporary directory:
/usr/bin/security export-smartcard -e "$tmpdir"

# Get path to Certificate for PIV Authentication:
piv_path=$(ls "$tmpdir" | /usr/bin/grep '^Certificate For PIV')

# Get User Principle Name from Certificate for PIV Authentication: 
UPN="$(/usr/bin/openssl asn1parse -i -dump -in "$tmpdir/$piv_path" -strparse $(/usr/bin/openssl asn1parse -i -dump -in "$tmpdir/$piv_path"  | /usr/bin/awk -F ':' '/X509v3 Subject Alternative Name/ {getline; print $1}') | /usr/bin/awk -F ':' '/UTF8STRING/{print $4}')"
# echo "UPN: $UPN"

# Clean up the temporary directory
/bin/rm -rf $tmpdir
}

createAltSecId (){
  altSecCheck=$("$dscl" . -read /Users/"$currentUser" AltSecurityIdentities 2>/dev/null | sed -n 's/.*Kerberos:\([^ ]*\).*/\1/p')
  if [[ "$UPN" = "" ]]; then
    echo "No UPN found for $currentUser" >> $logFile
    rv=$("$jamfHelper" -windowType "hud" -title "Smartcard Mapping" -description "Smartcard mapping was unsuccessful." -alignDescription "center" -button1 "Quit")
  elif [[ "$altSecCheck" = "$UPN" ]]; then
    echo "AltSec is already set to "$UPN"" >> $logFile
    rv=$("$jamfHelper" -windowType "hud" -title "Smartcard Mapping" -description "Smartcard mapping was already set." -alignDescription "center" -button1 "Quit")
  else
    echo "Adding AltSecurityIdentities" >> $logFile
    "$dscl" . -append /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
    result=$("$jamfHelper" \
                -icon $LOGO_POSIX \
                -windowType hud \
                -title "$PROMPT_TITLE" \
                -timeout 90 \
                -countdown -countdownPrompt "You will be automatically logged out in  " -alignCountdown center \
                -alignHeading "center" \
                -alignDescription "left" \
                -description "Token pairing successful!
                
                To complete the pairing, please remove and reinsert your token (Smartcard/Yubikey). You will be automatically logged out in  " \
                -lockHUD \
                -iconSize 100 \
                -button1 "Logout Now" \
                )
        if [[ "$result" == 0 ]]; then
                # perform button 1 action
                /bin/launchctl bootout gui/$(id -u $currentUser)
                exit 0
        fi
  fi
}

createMapping (){
if [ ! -f /etc/SmartcardLogin.plist ];then
/bin/cat > "/etc/SmartcardLogin.plist" << 'Attr_Mapping'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
     <key>AttributeMapping</key>
     <dict>
          <key>fields</key>
          <array>
               <string>NT Principal Name</string>
          </array>
          <key>formatString</key>
          <string>Kerberos:$1</string>
          <key>dsAttributeString</key>
          <string>dsAttrTypeStandard:AltSecurityIdentities</string>
     </dict>
     <key>TrustedAuthorities</key>
	   <array>
		  <string></string>
	   </array>
     <key>NotEnforcedGroup</key>
     <string></string>
</dict>
</plist>
Attr_Mapping
fi
}

prompt
checkForPaired
getUPN
createAltSecId
createMapping
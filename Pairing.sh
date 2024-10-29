#!/bin/bash

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
                -button1 "$button1" \
                )
        if [[ "$result" == 0 ]]; then
                # perform button 1 action
                /bin/launchctl bootout gui/$(id -u $currentUser)
                exit 0
        fi
  fi
}
#!/bin/bash
#
####################################################################################################
#
# The Apple Software is provided by Apple on an "AS IS" basis. APPLE
# MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
# OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
#
# IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
# MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
# AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#
# Smartcard-Remapping.sh
#
# This process is intended to unpair/un-map a smart card/PIV/CAC/Yubikey from a user account, and then map it again.
#
# unmapping
# It deletes the AltSecurityIdentities Kerberos entry from the current user's record.
# /usr/bin/dscl . -delete /Users/"$currentUser" AltSecurityIdentities
#
# It unpairs the smart card/PIV/CAC/Yubikey from a user account.
# /usr/sbin/sc_auth unpair -u "$currentUser"
#
# re-mapping
# The "Subject Alternative Name/NT Principal Name" from the card is mapped to "AltSecurityIdentities Kerberos" in
# the local directory services using dscl.
# UPN="Subject Alternative Name/NT Principal Name" from the card
# dscl . -create /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
#
ScriptVersion="2024-03-14"
# v2024-02-05 -Initial Version
# v2024-03-14 -Updated deleteSmartCard – added an addition dscl command to remove FVTokenSecret if it persistant
#
####################################################################################################
#
# LOGGING AND LOG FILES
#
####################################################################################################
logFile="/private/var/log/smartcard-management.log"
/usr/bin/touch "$logFile"
# Purpose: Provides custom logging for the application
# Use: log "text to log"
# Dependencies: logFile variable needs to be defined

Shell_Script_Name="$(/usr/bin/basename "${0}")"
dateFormat=$(/bin/date "+%Y-%m-%d %H:%M:%S %Z:")
function log () {
# Send the echo to stdout
/bin/echo $1
# Send the echo to the logFile
/bin/echo ${dateFormat} ${Shell_Script_Name}: $1 >> "${logFile}"
}
#
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
####################################################################################################

# HARDCODED VALUES ARE SET HERE
unset TRY_Check_for_PIV_Auth_Cert
unset TRY_verifypin
unset SmartCardPIN

# Custom Configuration Profile Domain
ConfigurationProfileDomain="com.smartcard.workflow.settings"

# macOS version
sw_vers_Full=$(/usr/bin/sw_vers -productVersion)
sw_vers_Full_Integer=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F. '{for(i=1; i<=NF; i++) {printf("%02d",$i)}}')
sw_vers_Major=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f 1,2)
sw_vers_Major_Integer=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f 1,2 | /usr/bin/awk -F. '{for(i=1; i<=NF; i++) {printf("%02d",$i)}}')
sw_vers_MajorNumber=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f 2)

# Jamf Environmental Positional Variables.
# $1 Mount Point
# $2 Computer Name
# $3 Current User Name - This can only be used with policies triggered by login or logout.
# Declare the Environmental Positional Variables so the can be used in function calls.
mountPoint=$1
computerName=$2
username=$3
currentUser=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
currentUserUID=$(id -u "$currentUser")
computerName=$(/usr/sbin/scutil --get ComputerName)

log "Preparing to map smart card for $currentUser"
log "${computerName} is running macOS version ${sw_vers_Full}"

######
# HARDCODED VALUE FOR "ImageFilePath" IS SET HERE
# Jamf Parameter Value Label - Image file path
# A Jamf self service icon can be pulled down right from the jamf server.
# Right click on a self service icon to get the url - https://your.jamf.server/icon?id=XX
ImageFilePath="/System/Library/Frameworks/CryptoTokenKit.framework/ctkbind.app/Contents/Resources/AppIcon.icns"

# CHECK TO SEE IF A VALUE WAS SPECIFIED VIA CONFIGURLATION PROFILE IF SO, ASSIGN TO "ImageFilePath"
# If a value is specified via a configuration profile, it will override the hardcoded value in the script.
ImageFilePath_ConfigProfile=$(/usr/bin/defaults read /Library/Managed\ Preferences/${ConfigurationProfileDomain} ImageFilePath 2> /dev/null)
if [ "$ImageFilePath_ConfigProfile" != "" ];then
log "ImageFilePath_ConfigProfile is $ImageFilePath_ConfigProfile"
ImageFilePath="$ImageFilePath_ConfigProfile"
fi

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO "ImageFilePath"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [ "$4" != "" ];then
ImageFilePath="$4"
fi

# If an http(s) url is specified, get the icon from the url
if [[ "$ImageFilePath" = "http"* ]] ; then
/usr/bin/curl --output "/tmp/ImageFile" "$ImageFilePath"
ImageFilePath="/tmp/ImageFile"
/bin/echo "$ImageFilePath"
# If the path ends with *.app use the app icon
elif [[ "$ImageFilePath" = *".app" ]] || [[ "$ImageFilePath" = *".prefPane" ]] ; then
CFBundleIconFile=$(/usr/bin/defaults read "$ImageFilePath"/Contents/Info.plist CFBundleIconFile 2> /dev/null)
CFBundleIconName=$(/usr/bin/defaults read "$ImageFilePath"/Contents/Info.plist CFBundleIconName 2> /dev/null)
if [[ "${CFBundleIconFile}" ]] ; then
# If the app icon is in Contents/Resources copy it to /tmp/ImageFile.icns
IconFileFullPath="$ImageFilePath"/Contents/Resources/"$CFBundleIconFile"
/bin/cp "$IconFileFullPath"* "/tmp/IconFile"
ImageFilePath="/tmp/ImageFile"
/bin/echo "$ImageFilePath"
elif [[ "$CFBundleIconName" ]] ; then
# If the app icon in embedded within the Assets.car
/usr/bin/iconutil -c icns "$ImageFilePath"/Contents/Resources/Assets.car "$CFBundleIconName" -o /tmp/ImageFile.icns
/bin/mv "/tmp/ImageFile.icns" "/tmp/ImageFile" #remove icns from the file name
ImageFilePath="/tmp/ImageFile"
/bin/echo "$ImageFilePath"
else
ImageFilePath=""
fi
fi
log "ImageFilePath is $ImageFilePath"
######

####################################################################################################
#
# Functions to call on
#
####################################################################################################

#
### Ensure we are running this script as root ###
function rootcheck () {
# log "Begin ${FUNCNAME[0]}"
if [ "$(/usr/bin/whoami)" != "root" ]; then
log "This script must be run as root or sudo."
exit 1
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Wait for the Dock.
function Wait_For_Dock () {
# log "Begin ${FUNCNAME[0]}"
dockStatus=$(/usr/bin/pgrep -x Dock)
while [ "$dockStatus" == "" ]; do
/bin/sleep 2
dockStatus=$(/usr/bin/pgrep -x Dock)
done
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Intro Message.
function IntroMessage (){
# log "Begin ${FUNCNAME[0]}"
Message="This will re-map a smart card for the user $currentUser. \nDo NOT continue unless you know your account pasword and your smart card PIN. \n\nPlease insert your smart card to begin. \nv${ScriptVersion}"
#
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
# Stop everything if the cancel button is pressed.
if [ $? -eq 1 ]; then
log "${currentUser} canceled smart card mapping process."
exit 0
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Prompt the user to insert card.
function Check_for_PIV_Auth_Cert (){
# log "Begin ${FUNCNAME[0]}"
# Command to force a restart of USB services for some smart card readers
/usr/bin/killall - STOP usbd
# Check for a smart card with a PIV Authentication certificate
PIV_Auth_Cert_Count=$(/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/sbin/sc_auth identities | /usr/bin/grep -c "PIV Authentication")
#
TRY_Check_for_PIV_Auth_Cert=1
while [[ ${PIV_Auth_Cert_Count} -ne 1 ]]; do
if [ "$TRY_Check_for_PIV_Auth_Cert" -eq 5 ]; then
Message="This smart card is not recognized. \nPlease contact you system administrator."
button1="Cancel"
log "${Message}"
log "${currentUser} canceled smart card mapping process."
/usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" buttons {\"${button1}\"} default button 1 giving up after 30" > /dev/null &
unset TRY_Check_for_PIV_Auth_Cert
exit 0
else
(( TRY_Check_for_PIV_Auth_Cert++ ))
if [[ ${PIV_Auth_Cert_Count} -lt 1 ]]; then
Message="Smart card not detected. \nPlease re-insert your smart card to begin."
elif [[ ${PIV_Auth_Cert_Count} -gt 1 ]]; then
Message="Multiple smart cards detected. \nPlease insert only one smart card."
fi
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
# Stop everything if the cancel button is pressed.
if [ $? -eq 1 ]; then
log "${currentUser} canceled smart card mapping process."
exit 0
fi
/bin/sleep 1
PIV_Auth_Cert_Count=$(/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/sbin/sc_auth identities | /usr/bin/grep -c "PIV Authentication")
fi
done
log "Smart card detected"
# log "End ${FUNCNAME[0]}"
}
###
#

#
### verify Smart Card PIN ###
function verifySmartCardPIN () {
# log "Begin ${FUNCNAME[0]}"
smartCardVerification=$(/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/sbin/sc_auth verifypin -p "${SmartCardPIN}" 2>/dev/null)
# Checking for "PIN verified" or "PIN verifyied" due to spelling error in macOS Catalina sc_auth verifypin command
# Big Sur returns "PIN verifyied" Note the extra "y"
# "$smartCardVerification" == "" is there if using - Two Canoes Remote Access - https://twocanoes.com/solutions/remote-access/
if [[ "$smartCardVerification" =~ "PIN verified" ]] || [[ "$smartCardVerification" =~ "PIN verifyied" ]] || [[ "$smartCardVerification" == "" ]] ; then
log "${currentUser} smart card PIN verified."
return 0
else
return 1
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Test Smart Card PIN ###
function Test_Smart_Card_PIN () {
# log "Begin ${FUNCNAME[0]}"
Message="Please verify your Smart Card PIN."
title="Smart Card PIN"
SmartCardPIN=$(/usr/bin/osascript -e "display dialog \"${Message}\" default answer \"\" with hidden answer with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" giving up after 86400" -e "return text returned of result")

if [ $? -eq 1 ]; then
log "${currentUser} canceled smart card mapping process."
unset SmartCardPIN
exit 0
fi

if [[ -z "${SmartCardPIN}" ]]; then
SmartCardPIN="emptyPIN"
fi

TRY_verifypin=1

until verifySmartCardPIN; do
# log "This is TRY_verifypin number $TRY_verifypin at the start of the Unitl loop"
if [ "$TRY_verifypin" -eq 2 ]; then
Message="You've made two incorrect PIN attempts. Exiting now."
button1="Cancel"
log "${Message}"
log "${currentUser} canceled smart card mapping process."
/usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" buttons {\"${button1}\"} default button 1 giving up after 30" > /dev/null &
unset SmartCardPIN
exit 0
else
# Checking for "PIN verified" or "PIN verifyied" due to spelling error in macOS Catalina sc_auth verifypin command
# Catalina returns "PIN verifyied" Note the extra y
(( TRY_verifypin++ ))

Message="That PIN was incorrect. Please try again:"
unset SmartCardPIN
SmartCardPIN=$(/usr/bin/osascript -e "display dialog \"${Message}\" default answer \"\" with hidden answer with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" giving up after 86400" -e "return text returned of result")
if [ $? -eq 1 ]; then
log "${currentUser} canceled smart card mapping process."
unset SmartCardPIN
exit 0
fi

if [[ -z "${SmartCardPIN}" ]]; then
SmartCardPIN="emptyPIN"
fi
fi
done

unset SmartCardPIN
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Get User Password ###
function Get_UserPassword () {
# log "Begin ${FUNCNAME[0]}"
Message="Please verify your account password."
title="Password"
icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FileVaultIcon.icns"
UserPassword=$(/usr/bin/osascript -e "display dialog \"${Message}\" default answer \"\" with hidden answer with title \"${title}\" with icon POSIX file \"${icon}\" giving up after 86400" -e "return text returned of result")
if [ $? -eq 1 ]; then
log "${currentUser} canceled - Exiting"
UserPassword=""
unset UserPassword
exit 0
fi
TRY_UserPassword=1
until /usr/bin/dscl /Search -authonly "$currentUser" "$UserPassword" &>/dev/null; do
 (( TRY_UserPassword++ ))
 Message="That password was incorrect. Please try again:"
 /bin/echo "Prompting $currentUser for their Mac password (attempt $TRY_UserPassword)..."
 UserPassword=$(/usr/bin/osascript -e "display dialog \"${Message}\" default answer \"\" with hidden answer with title \"${title}\" with icon POSIX file \"${icon}\" giving up after 86400" -e "return text returned of result")
if [ $? -eq 1 ]; then
log "${currentUser} canceled - Exiting"
UserPassword=""
unset UserPassword
exit 0
elif (( TRY_UserPassword >= 3 )); then
 Message="You've made three incorrect password attempts. Exiting now."
button1="Cancel"
/usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${icon}\" buttons {\"${button1}\"} default button 1 giving up after 30" > /dev/null &
log "${Message}"
log "${currentUser} canceled - Exiting"
UserPassword=""
unset UserPassword
exit 0
fi
done

if [[ -z "${UserPassword}" ]] ; then
log "${currentUser} UserPassword not defined - Exiting"
UserPassword=""
unset UserPassword
exit 0
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Delete current user's smart card
function deleteSmartCard (){
# log "Begin ${FUNCNAME[0]}"

# Get amidentity hash if it exists
amidentityHash="$(/usr/bin/dscl -plist . -read /Users/"$currentUser" AuthenticationAuthority | /usr/bin/xmllint --xpath 'string(//string[contains(text(),"amidentity")])' - | /usr/bin/awk -F';' '/amidentity/{print $3}')"
while [[ "${amidentityHash}" ]] ; do
log "Unpairing ${currentUser} smart card"
/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/sbin/sc_auth unpair -u "$currentUser" -h "$amidentityHash"
log "Removing ${currentUser} FVTokenSecret"
/bin/launchctl asuser "0" /usr/bin/sudo -iu "root" /usr/sbin/sc_auth filevault -o disable -u "$currentUser" -h "$amidentityHash"
amidentityHash="$(/usr/bin/dscl -plist . -read /Users/"$currentUser" AuthenticationAuthority | /usr/bin/xmllint --xpath 'string(//string[contains(text(),"amidentity")])' - | /usr/bin/awk -F';' '/amidentity/{print $3}')"
done
log "Unpairing ${currentUser} smart card"
/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/sbin/sc_auth unpair -u "$currentUser"
log "Removing ${currentUser} FVTokenSecret"
/bin/launchctl asuser "0" /usr/bin/sudo -iu "root" /usr/sbin/sc_auth filevault -o disable -u "$currentUser"
/usr/sbin/diskutil apfs updatePreboot /


# Delete any existing mapped smart cards and FVTokenSecret
log "Unmapping ${currentUser} smart card"
/usr/bin/dscl . -delete /Users/"$currentUser" AltSecurityIdentities
/usr/bin/dscl . -delete /Users/"$currentUser" dsAttrTypeNative:FVTokenSecret

# Command to force a restart of USB services for some smart card readers
/usr/bin/killall - STOP usbd

altSecCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AltSecurityIdentities 2> /dev/null | /usr/bin/grep -c Kerberos)
tokenCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AuthenticationAuthority 2> /dev/null | /usr/bin/grep -c tokenidentity)
amidentityCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AuthenticationAuthority 2> /dev/null | /usr/bin/grep -c amidentity)
FVTokenSecret=$(/usr/bin/dscl . -read /Users/"$currentUser" dsAttrTypeNative:FVTokenSecret 2> /dev/null)

if [[ "$altSecCheck" == 0 ]] && [[ "$tokenCheck" == 0 ]] && [[ "$amidentityCheck" == 0 ]] && [[ -z "$FVTokenSecret" ]]; then
# Unmapping/Unpairing succeeded
# Begin dialog box message
Message="Successfully unmapped the smart card from $currentUser."
log "${currentUser} - ${Message}"
# /usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"$Message\" with title \"Smart Card Unmapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Ok\"} default button 1" > /dev/null &
else
# Unmapping/Unpairing failed
# Begin dialog box message
Message="The unmapping process failed. \n\nPlease contact your administrator for assistance."
# End dialog box message
log "${currentUser} - ${Message}"
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"$Message\" with title \"Smart Card Unmapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Ok\"} default button 1" > /dev/null &
log "Setting PIVMandatory to false"
/bin/mkdir -p /private/var/EnterpriseManagement/
/usr/bin/defaults write "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory -bool false 2> /dev/null
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatoryUndoDate 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVMandatory"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" NTPrincipalName 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "NTPrincipalName"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVAuthCert_Expiration 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVAuthCert_Expiration"
 /usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Get the PIV Identity Hash for UPN ###
function getUPN(){
# log "Begin ${FUNCNAME[0]}"
# Create temp dir to export certs
tmpdir=$(/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/bin/mktemp -d)

# Dump card's certs
# /usr/bin/security export-smartcard -e "$tmpdir"
/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/bin/security export-smartcard -e "${tmpdir}"

# Get PIV cert
piv_path=$(/bin/ls "$tmpdir" | /usr/bin/grep '^Certificate For PIV')

# Get UPN
UPN=$(/usr/bin/openssl asn1parse -i -dump -in "$tmpdir/$piv_path" -strparse $(/usr/bin/openssl asn1parse -i -dump -in "$tmpdir/$piv_path" | /usr/bin/awk -F ':' '/X509v3 Subject Alternative Name/ {getline; print $1}') | /usr/bin/awk -F ':' '/UTF8STRING/{print $4}')
log "UPN: $UPN"

checkPIVAuthCertExpiration

# clean up
/bin/rm -rf $tmpdir
# log "End ${FUNCNAME[0]}"
}
###
#

#
### check the PIV Authentication Certificate Expiration ###
function checkPIVAuthCertExpiration(){
# log "Begin ${FUNCNAME[0]}"
CertExpiration_date=$(/usr/bin/openssl x509 -enddate -noout -in "$tmpdir/$piv_path" | /usr/bin/awk -F '=' '{print $NF}' | /usr/bin/awk '{print $1,$2,$4}')
CertExpiration_0_Days=$(/usr/bin/openssl x509 -checkend 0 -in "$tmpdir/$piv_path") #
CertExpiration_4_Weeks=$(/usr/bin/openssl x509 -checkend 2419200 -in "$tmpdir/$piv_path") # 4 weeks = 2419200 seconds
CertExpiration_26_Weeks=$(/usr/bin/openssl x509 -checkend 15724800 -in "$tmpdir/$piv_path") # 26 weeks = 15724800
if [[ "$CertExpiration_0_Days" == "Certificate will expire" ]]; then
# PIV Authentication Certificate has expired
title="Certificate Expired"
Message="The PIV Authentication certificate on this smart card expired ${CertExpiration_date}. \n\nYou must renew this smart card before you can use it."
log "${Message}"
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Cancel\"} default button 1 giving up after 30" > /dev/null &
log "Setting PIVMandatory to false"
/bin/mkdir -p /private/var/EnterpriseManagement/
/usr/bin/defaults write "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory -bool false 2> /dev/null
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatoryUndoDate 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVMandatory"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" NTPrincipalName 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "NTPrincipalName"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVAuthCert_Expiration 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVAuthCert_Expiration"
 /usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
exit 0
elif [[ "$CertExpiration_4_Weeks" == "Certificate will expire" ]]; then
# PIV Authentication Certificate will expire within 4 weeks
title="Certificate Expiring"
Message="The PIV Authentication certificate on this smart card will expire ${CertExpiration_date}. \n\nPlease renew this smart card as soon as possible. \nUsing this smart card prior to renewing is not recommended."
log "${Message}"
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Cancel\" , \"Continue\"} default button 1 giving up after 30"
# Stop everything if the cancel button is pressed.
if [ $? -eq 1 ]; then
log "${currentUser} canceled smart card mapping process."
log "Setting PIVMandatory to false"
/bin/mkdir -p /private/var/EnterpriseManagement/
/usr/bin/defaults write "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory -bool false 2> /dev/null
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatoryUndoDate 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVMandatory"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" NTPrincipalName 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "NTPrincipalName"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVAuthCert_Expiration 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVAuthCert_Expiration"
/usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
exit 0
fi
elif [[ "$CertExpiration_26_Weeks" == "Certificate will expire" ]]; then
# PIV Authentication Certificate will expire within 6 months
title="Certificate Expiring"
Message="The PIV Authentication certificate on this smart card will expire ${CertExpiration_date}. \n\nPlease renew this smart card as soon as possible."
log "${Message}"
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
# Stop everything if the cancel button is pressed.
if [ $? -eq 1 ]; then
log "${currentUser} canceled smart card mapping process."
log "Setting PIVMandatory to false"
/bin/mkdir -p /private/var/EnterpriseManagement/
/usr/bin/defaults write "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory -bool false 2> /dev/null
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatoryUndoDate 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVMandatory"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" NTPrincipalName 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "NTPrincipalName"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVAuthCert_Expiration 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVAuthCert_Expiration"
/usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
exit 0
fi
else
log "PIV Authentication Certificate is not expired and is not expiring soon"
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Create AltSecurityIdentities Kerberos for current user
function createAltSecId (){
# log "Begin ${FUNCNAME[0]}"
altSecCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AltSecurityIdentities 2> /dev/null | /usr/bin/sed -n 's/.*Kerberos:\([^ ]*\).*/\1/p')
#
if [ -z "$UPN" ]; then
# The smart card does not have a properly configured PIV Authentication cert with a Subject Alternative Name and NT Principal Name.
# dialog box message
Message="Smart card mapping was unsuccessful. NT Principal Name is not properly configured for this card. \n\nPlease contact your administrator for assistance."
log "${currentUser} - ${Message}"
rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
log "Setting PIVMandatory to false"
/bin/mkdir -p /private/var/EnterpriseManagement/
/usr/bin/defaults write "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory -bool false 2> /dev/null
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatoryUndoDate 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVMandatory"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" NTPrincipalName 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "NTPrincipalName"
/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVAuthCert_Expiration 2> /dev/null
/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVAuthCert_Expiration"
 /usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
exit 0
else
# The smart card is properly configured and will be mapped to this user.
# Begin dialog box message
Message1="Successfully added $UPN to $currentUser. \n\n!!!YOUR ACTION REQUIRED!!! \n\nPlease remove and re-insert your smart card."
Message2="!!!YOUR ACTION REQUIRED!!! \n\nClick Continue to lock the screen. \n\nWait 10 seconds, then use your PIN to unlock the screen. \n\nYou may be prompted once for your keychain password after unlocking the screen."
# Create new AltSecurityIdentities
/usr/bin/dscl . -create /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
# Command to force a restart of USB services for some smart card readers
/usr/bin/killall - STOP usbd
log "${Message1}"
rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message1}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message2}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
MarkPIVMandatory_Yes_or_No
/usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
testFVTokenSecret_after_ScreenSaverEngine
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Wait for ScreenSaverEngine to to stop then testFVTokenSecret
function testFVTokenSecret_after_ScreenSaverEngine () {
# log "Begin ${FUNCNAME[0]}"
# Set screenUnlockMode to behave like pre-Sonoma. This will allow the login keychain password prompt to appear after PIN unlock.
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow screenUnlockMode -int 0
# Use screen saver to lock the screen. THis will force the user to unlock using their smart card and PIN.
/bin/launchctl asuser "$currentUserUID" /usr/bin/sudo -iu "$currentUser" /usr/bin/open /System/Library/CoreServices/ScreenSaverEngine.app

log "Waiting for ScreenSaverEngine to end"
/bin/sleep 5
ScreenSaverEngineStatus=$(/usr/bin/pgrep -x ScreenSaverEngine 2> /dev/null)
while [ "$ScreenSaverEngineStatus" ]; do
/bin/sleep 5
ScreenSaverEngineStatus=$(/usr/bin/pgrep -x ScreenSaverEngine 2> /dev/null)
done

# Undo screenUnlockMode
/usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow screenUnlockMode

testFVTokenSecret
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Test to see if the smart card KMK was used to create a FVTokenSecret and encrypt the login.keychain
function testFVTokenSecret(){
# log "Begin ${FUNCNAME[0]}"
FVTokenSecret=$(/usr/bin/dscl . -read /Users/"$currentUser" dsAttrTypeNative:FVTokenSecret 2> /dev/null)

if [[ ! "${FVTokenSecret}" ]]; then
log "FVTokenSecret is NOT properly configured for ${currentUser}".
log "Prompting ${currentUser} to logout to complete smart card mapping."
Message="!!!LOG OUT REQUIRED!!! \n\nYou must log out now to enable smart card authentication. \n\nSave all files and close all apps before proceeding. \nYou will automatically be logged out after clicking the Log Out button. \n\nOnce logged out please log back in. \n\nYou will be prompted once for your keychain password when logging back in."
#
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Log Out\"} default button 1"
# Create script and LaunchAgent to Log out current user
Create_LogOut_Script
Create_LogOut_LaunchAgent
elif [[ "$LogOutWhenComplete" = "yes" ]]; then
/usr/sbin/diskutil apfs updatePreboot /
log "FVTokenSecret is configured for ${currentUser}".
log "Smart card mapping complete. Prompting ${currentUser} to logout."
Message="!!!LOG OUT REQUIRED!!! \n\nYou must log out now to enable smart card authentication. \n\nSave all files and close all apps before proceeding. \nYou will automatically be logged out after clicking the Log Out button."
#
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Log Out\"} default button 1"
# Create script and LaunchAgent to Log out current user
Create_LogOut_Script
Create_LogOut_LaunchAgent
log "Smart card mapping complete. Logout not required."
else
/usr/sbin/diskutil apfs updatePreboot /
Message="Smart card mapping complete."
log "FVTokenSecret is configured for ${currentUser}".
log "Smart card mapping complete."
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1" &
fi
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Create script LogOutUser.sh ###
function Create_LogOut_Script () {
log "Begin ${FUNCNAME[0]}"
/bin/cat > "/private/tmp/LogOutUser.sh" << 'SCRIPT'
#!/bin/sh
#
currentUser=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
#
/usr/bin/caffeinate -i -s -d -t 60 &
/bin/sleep 5

# Remove LogOutUser script and com.smartcard.LogOutUser LaunchAgent
/bin/rm /private/tmp/LogOutUser.sh
/bin/rm /Library/LaunchAgents/com.smartcard.LogOutUser.plist
#
# Log user out
/bin/launchctl bootout user/$(/usr/bin/id -u "$currentUser")

# Unload LaunchAgent com.jamf.LogOutUser
/bin/launchctl bootout system/com.smartcard.LogOutUser
#
SCRIPT
# Set permissions for script
/usr/sbin/chown root:wheel /private/tmp/LogOutUser.sh
/bin/chmod 755 /private/tmp/LogOutUser.sh
# log "End ${FUNCNAME[0]}"
}
###
#

#
### Create LaunchAgent com.smartcard.LogOutUser.plist ###
function Create_LogOut_LaunchAgent () {
log "Begin ${FUNCNAME[0]}"
/bin/cat > "/Library/LaunchAgents/com.smartcard.LogOutUser.plist" << 'LaunchAgent'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" http://www.apple.com/DTDs/PropertyList-1.0.dtd>
<plist version="1.0">
<dict>
<key>Label</key>
<string>com.smartcard.LogOutUser</string>
<key>ProgramArguments</key>
<array>
<string>/private/tmp/LogOutUser.sh</string>
</array>
<key>LaunchOnlyOnce</key>
<true/>
<key>RunAtLoad</key>
<true/>
</dict>
</plist>
LaunchAgent
# Set permissions for LaunchAgent
/usr/sbin/chown root:wheel /Library/LaunchAgents/com.smartcard.LogOutUser.plist
/bin/chmod 644 /Library/LaunchAgents/com.smartcard.LogOutUser.plist
/usr/bin/plutil -convert xml1 /Library/LaunchAgents/com.smartcard.LogOutUser.plist
# Run LaunchAgent
/bin/launchctl bootstrap system/ /Library/LaunchAgents/com.smartcard.LogOutUser.plist
# log "End ${FUNCNAME[0]}"
}
###
#

####################################################################################################
#
# SCRIPT CONTENTS
#
####################################################################################################

if [[ "$sw_vers_Major_Integer" -lt 1014 ]]; then
/bin/echo "This script requires 10.14 or greater. Exiting now."
exit 1
fi

rootcheck

Wait_For_Dock

Check_current_user_for_mapped_smart_card

IntroMessage

Check_for_PIV_Auth_Cert

Test_Smart_Card_PIN

Get_UserPassword

deleteSmartCard

getUPN

createAltSecId

exit 0

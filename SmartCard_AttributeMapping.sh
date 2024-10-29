#!/bin/bash
#
####################################################################################################
#
# The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
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
#	Smartcard-AttributeMapping.sh
#
# This process is intended to pair/map a smart card/PIV/CAC/Yubikey to a local user account using attribute mapping.
#
# The "Subject Alternative Name/NT Principal Name" from the card is mapped to "AltSecurityIdentities Kerberos" in
# the local directory services using dscl.
# UPN="Subject Alternative Name/NT Principal Name" from the card
# dscl . -create /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
#
# "/etc/SmartcardLogin.plist" must also be configured for offline smart card login via kerberos caching.
# "man SmartCardServices" for the offline smart card login via kerberos caching example.
#
# Mac systems do not have to be bound to AD to use attribute mapping. However, if a Mac system is bound to AD
# additional AD users will be able to log in (creating an AD mobile account) using smart cards and/or username and password.
# If the smart card does not include "Subject Alternative Name/NT Principal Name" this process will fail.#
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
computerName=$(/usr/sbin/scutil --get ComputerName)
#
/bin/echo "Current User is $currentUser"
/bin/echo "$computerName" is running OS X version "$sw_vers_Full"
#

# HARDCODED VALUE FOR "ImageFilePath" IS SET HERE
# Jamf Parameter Value Label - Image file path (See script for example)
# A Jamf self service icon can be pulled down right from the jamf server.
# Righ click on an self service icon to get the url - https://your.jamf.server/icon?id=XX 
ImageFilePath="/System/Library/Frameworks/CryptoTokenKit.framework/ctkbind.app/Contents/Resources/AppIcon.icns"

# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO "ImageFilePath"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [ "$4" != "" ];then
	ImageFilePath="$4"
fi
# If an http(s) url is specified, get the icon from the url
if [[ "$ImageFilePath" = *"http"* ]] ; then
	/usr/bin/curl --output "/tmp/ImageFile" "$ImageFilePath"
	ImageFilePath="/tmp/ImageFile"
	/bin/echo "ImageFilePath is $ImageFilePath"
else
	ImageFilePath="$ImageFilePath"
	/bin/echo "ImageFilePath is $ImageFilePath"
fi

# HARDCODED VALUE FOR "MarkPIVMandatory" IS SET HERE
# Upon successful smart card mapping mark PIV Mandatory.
# Jamf Parameter Value Label - Mark as PIV Mandatory (yes|no)
MarkPIVMandatory="no"
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 5 AND, IF SO, ASSIGN TO "MarkPIVMandatory"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [ "$5" != "" ];then
	MarkPIVMandatory="$5"
fi
/bin/echo "MarkPIVMandatory: $MarkPIVMandatory"

# HARDCODED VALUE FOR "nonValid_smart_card_Users" IS SET HERE
# List of local users that should not be prompted to map a smart card
# Jamf Parameter Value Label - Non-valid smart card users (comma separated)
nonValid_smart_card_Users=""
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 6 AND, IF SO, ASSIGN TO "nonValid_smart_card_Users"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [ "$6" != "" ];then
	nonValid_smart_card_Users="$6"
fi
/bin/echo "nonValid_smart_card_Users: $nonValid_smart_card_Users"
#
####################################################################################################
#
# Functions to call on
#
####################################################################################################

#
### Ensure we are running this script as root ###
function rootcheck () {
# /bin/echo "Begin ${FUNCNAME[0]}"
if [ "$(/usr/bin/whoami)" != "root" ]; then
	# /bin/echo "This script must be run as root or sudo."
	exit 1
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Wait for the Dock.
function Wait_For_Dock () {
# /bin/echo "Begin ${FUNCNAME[0]}"
dockStatus=$(/usr/bin/pgrep -x Dock)
while [ "$dockStatus" == "" ]; do
  #/bin/echo "Dock is not loaded. Waiting."
  /bin/sleep 2
  dockStatus=$(/usr/bin/pgrep -x Dock)
done
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Check for nonValid smart card users.
function Check_For_nonValid_smart_card_Users () {
# /bin/echo "Begin ${FUNCNAME[0]}"
IFS=','
shopt -s nocasematch
for Each_nonValid_smart_card_User in $nonValid_smart_card_Users ; do
	currentUser=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
	if [[ "${currentUser}" == "$Each_nonValid_smart_card_User" ]]; then
		/bin/echo "Current user ${currentUser} is not intended to use a smart card."
		exit 0
	fi
done
shopt -u nocasematch
unset IFS

currentUser=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
currentUserUID=$(id -u "$currentUser")
if [[ "${currentUserUID}" -lt 501 ]]; then
	/bin/echo "Current user ${currentUser} is not intended to use a smart card."
	exit 0
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Check current user for mapped smart card
function checkForSmartCard (){
# /bin/echo "Begin ${FUNCNAME[0]}"
altSecCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AltSecurityIdentities 2> /dev/null | /usr/bin/sed -n 's/.*Kerberos:\([^ ]*\).*/\1/p')
altSecCheckCount=$(/usr/bin/dscl . -read /Users/"$currentUser" AltSecurityIdentities 2> /dev/null | /usr/bin/grep -c Kerberos)

if [[ "$altSecCheckCount" != 0 ]]; then
	# Begin dialog box message
    Message="Current user ${currentUser} already has a smart card.
You must un-map the current ${altSecCheck} smart card before proceeding."
   	/bin/echo "${Message}"
    /usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Ok\"} default button 1"
	exit 0
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Mark system as PIV Mandatory ###
function MarkPIVMandatoryYes () {
# /bin/echo "Begin ${FUNCNAME[0]}"
if [ "$MarkPIVMandatory" = "yes" ]; then
	/bin/mkdir -p /private/var/EnterpriseManagement/
	/usr/bin/defaults write "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory -bool true 2> /dev/null
	/usr/bin/defaults delete "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatoryUndoDate 2> /dev/null
	/usr/bin/defaults -read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" 2> /dev/null | /usr/bin/grep "PIVMandatory"
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Verify that CryptoTokenKit is enabled and functioning ###
function EnableCTK () {
# /bin/echo "Begin ${FUNCNAME[0]}"
/usr/bin/security smartcards token -e com.apple.CryptoTokenKit.pivtoken > /dev/null
/usr/bin/defaults delete /Library/Preferences/com.apple.security.smartcard DisabledTokens 2> /dev/null
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Intro Message.
function IntroMessage (){
# /bin/echo "Begin ${FUNCNAME[0]}"
#
Message="This will enable smart card login for the user $currentUser.
Do NOT continue unless you know your PIN.

Please insert your smart card to begin."
#
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
# Stop everything if the cancel button is pressed.
if [ $? -eq 1 ]; then
	/bin/echo "${currentUser} canceled smart card mapping process."
	exit 0
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Prompt the user to insert card.
function Check_for_PIV_Auth_Cert (){
# /bin/echo "Begin ${FUNCNAME[0]}"
PIV_Auth_Cert_Count=$(/usr/sbin/sc_auth identities | /usr/bin/grep -c "PIV Authentication")
#
TRY_Check_for_PIV_Auth_Cert=1
while [[ ${PIV_Auth_Cert_Count} -ne 1 ]]; do
	# /bin/echo "This is TRY_Check_for_PIV_Auth_Cert number $TRY_Check_for_PIV_Auth_Cert at the start of the Unitl loop"
	if [ "$TRY_Check_for_PIV_Auth_Cert" -eq 5 ]; then
		Message="This smart card is not recognized. \nPlease contact you system administrator."
		button1="Cancel"
		/usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" buttons {\"${button1}\"} default button 1 giving up after 30"
		unset TRY_Check_for_PIV_Auth_Cert
		exit 0
	else
		#/bin/echo "TRY_Check_for_PIV_Auth_Cert $TRY_Check_for_PIV_Auth_Cert"
		(( TRY_Check_for_PIV_Auth_Cert++ ))
		if [[ ${PIV_Auth_Cert_Count} -lt 1 ]]; then
			Message="Smart card not detected. \nPlease re-insert your smart card to begin."	
		elif [[ ${PIV_Auth_Cert_Count} -gt 1 ]]; then
			Message="Multiple smart cards detected. \nPlease insert only one smart card."
		fi
		/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
		# Stop everything if the cancel button is pressed.
		if [ $? -eq 1 ]; then
			/bin/echo "${currentUser} canceled smart card mapping process."
			exit 0
		fi
		/bin/sleep 1
		PIV_Auth_Cert_Count=$(/usr/sbin/sc_auth identities | /usr/bin/grep -c "PIV Authentication")
	fi
done
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### verify Smart Card PIN ###
function verifySmartCardPIN () {
smartCardVerification=$(/usr/sbin/sc_auth verifypin -p "${SmartCardPIN}" 2>/dev/null)
# Checking for "PIN verified" or "PIN verifyied" due to spelling error in macOS Catalina sc_auth verifypin command
# Big Sure returns "PIN verifyied" Note the extra "y"
if [[ "$smartCardVerification" =~ "PIN verified" ]] || [[ "$smartCardVerification" =~ "PIN verifyied" ]]; then
	#return "$smartCardVerification"
	return 0
else
	return 1
fi
}
###
#

#
### Test Smart Card PIN ###
function Test_Smart_Card_PIN () {
# /bin/echo "Begin ${FUNCNAME[0]}"
Message="Please verify your Smart Card PIN."
# /bin/echo "${Message}"
title="Smart Card PIN"
SmartCardPIN=$(/usr/bin/osascript -e "display dialog \"${Message}\" default answer \"\" with hidden answer with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" giving up after 86400" -e "return text returned of result")

if [ $? -eq 1 ]; then
	/bin/echo "${currentUser} canceled smart card mapping process."
	unset SmartCardPIN
	exit 0
fi

if [[ -z "${SmartCardPIN}" ]]; then
	SmartCardPIN="emptyPIN"
fi

TRY_verifypin=1

until verifySmartCardPIN; do
	# /bin/echo "This is TRY_verifypin number $TRY_verifypin at the start of the Unitl loop"
	if [ "$TRY_verifypin" -eq 2 ]; then
		Message="You've made two incorrect PIN attempts. Exiting now."
		button1="Cancel"
		/usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" buttons {\"${button1}\"} default button 1 giving up after 30"
		unset SmartCardPIN
		exit 0
	else
		# Checking for "PIN verified" or "PIN verifyied" due to spelling error in macOS Catalina sc_auth verifypin command
		# Catalina returns "PIN verifyied" Note the extra y
		(( TRY_verifypin++ ))
	
		Message="That PIN was incorrect. Please try again:"
		/bin/echo "Prompting $currentUser for their PIN (attempt $TRY_verifypin)..."
		unset SmartCardPIN
		SmartCardPIN=$(/usr/bin/osascript -e "display dialog \"${Message}\" default answer \"\" with hidden answer with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" giving up after 86400" -e "return text returned of result")
		if [ $? -eq 1 ]; then
			/bin/echo "${currentUser} canceled smart card mapping process."
			unset SmartCardPIN
			#SmartCardPIN=""
			exit 0
		fi

		if [[ -z "${SmartCardPIN}" ]]; then
			SmartCardPIN="emptyPIN"
		fi
	fi
done

unset SmartCardPIN
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Check for an already paired smart card ##
function checkForPaired (){
# /bin/echo "Begin ${FUNCNAME[0]}"
tokenCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AuthenticationAuthority | /usr/bin/grep -c tokenidentity)
if [[ "$tokenCheck" > 0 ]]; then
	/bin/echo "Unpair $currentUser"
	/usr/sbin/sc_auth unpair -u "$currentUser"
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Get the PIV Identity Hash for UPN ###
function getUPN(){
# /bin/echo "Begin ${FUNCNAME[0]}"
# Create temp dir to export certs
# tmpdir=$(/usr/bin/mktemp -d)
tmpdir=$(/bin/launchctl asuser "$currentUserUID" sudo -iu "$currentUser" /usr/bin/mktemp -d)

# Dump card's certs
# /usr/bin/security export-smartcard -e "$tmpdir"
/bin/launchctl asuser "$currentUserUID" sudo -iu "$currentUser" /usr/bin/security export-smartcard -e "${tmpdir}"

# Get PIV cert
piv_path=$(/bin/ls "$tmpdir" | /usr/bin/grep '^Certificate For PIV')

/bin/echo "Getting UPN"
UPN=$(/usr/bin/openssl asn1parse -i -dump -in "$tmpdir/$piv_path" -strparse $(/usr/bin/openssl asn1parse -i -dump -in "$tmpdir/$piv_path" | /usr/bin/awk -F ':' '/X509v3 Subject Alternative Name/ {getline; print $1}') | /usr/bin/awk -F ':' '/UTF8STRING/{print $4}')
/bin/echo "UPN: $UPN"

checkPIVAuthCertExpiration

# clean up
/bin/rm -rf $tmpdir

# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### check the PIV Authentication Certificate Expiration ###
function checkPIVAuthCertExpiration(){
# /bin/echo "Begin ${FUNCNAME[0]}"
CertExpiration_date=$(/usr/bin/openssl x509 -enddate -noout -in "$tmpdir/$piv_path" | /usr/bin/awk -F '=' '{print $NF}' | /usr/bin/awk '{print $1,$2,$4}')
CertExpiration_0_Days=$(/usr/bin/openssl x509 -checkend 0 -in "$tmpdir/$piv_path") #
CertExpiration_4_Weeks=$(/usr/bin/openssl x509 -checkend 2419200 -in "$tmpdir/$piv_path") # 4 weeks = 2419200 seconds
CertExpiration_26_Weeks=$(/usr/bin/openssl x509 -checkend 15724800 -in "$tmpdir/$piv_path") # 26 weeks = 15724800
if [[ "$CertExpiration_0_Days" == "Certificate will expire" ]]; then
	# PIV Authentication Certificate has expired
	/bin/echo "PIV Authentication Certificate has expired"
	title="Certificate Expired"
	Message="The PIV Authentication certificate on this smart card expired ${CertExpiration_date}. \n \nYou must renew this smart card before you can use it."
	/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"${title}\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Cancel\"} default button 1 giving up after 30"
	exit 0
	
elif [[ "$CertExpiration_4_Weeks" == "Certificate will expire" ]]; then
	# PIV Authentication Certificate will expire within 4 weeks
	/bin/echo "PIV Authentication Certificate will expire ${CertExpiration_date}"
	title="Certificate Expiring"
	Message="The PIV Authentication certificate on this smart card will expire ${CertExpiration_date}. \n \nPlease renew this smart card as soon as possible. \n Using this smart card prior to renewing is not recommended."
	/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Cancel\" , \"Continue\"} default button 1 giving up after 30"
	# Stop everything if the cancel button is pressed.
	if [ $? -eq 1 ]; then
		/bin/echo "${currentUser} canceled smart card mapping process."
		exit 0
	fi

elif [[ "$CertExpiration_26_Weeks" == "Certificate will expire" ]]; then
	# PIV Authentication Certificate will expire within 6 months
	/bin/echo "PIV Authentication Certificate will expire ${CertExpiration_date}"
	title="Certificate Expiring"
	Message="The PIV Authentication certificate on this smart card will expire ${CertExpiration_date}. \n \nPlease renew this smart card as soon as possible."
	/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
	# Stop everything if the cancel button is pressed.
	if [ $? -eq 1 ]; then
		/bin/echo "${currentUser} canceled smart card mapping process."
		exit 0
	fi
else
	/bin/echo "PIV Authentication Certificate is not expired or expiring soon"
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Create AltSecurityIdentities Kerberos for current user
function createAltSecId (){
# /bin/echo "Begin ${FUNCNAME[0]}"
altSecCheck=$(/usr/bin/dscl . -read /Users/"$currentUser" AltSecurityIdentities 2> /dev/null | /usr/bin/sed -n 's/.*Kerberos:\([^ ]*\).*/\1/p')
#
if [ -z "$UPN" ]; then
# The smart card does not have a properly configured PIV Authentication cert with a Subject Alternative Name and NT Principal Name.
# Begin dialog box message
	Message="Smart card mapping was unsuccessful. Subject Alternative Name is not properly configured for this card.

Please contact your administrator for assistance."
# End dialog box message
	/bin/echo "No UPN found for $currentUser"
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
    exit 0
#
#
elif [ "$altSecCheck" = "$UPN" ]; then
    # This smart card is already mapped to this user.
    # Begin dialog box message
    Message="Smart card mapping for $currentUser is already configured for this card."
    /bin/echo "${Message}"
    # End dialog box message
	#/bin/echo "AltSec is already set to "$UPN""
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
	MarkPIVMandatoryYes
#
#
else
	# The smart card is properly configured and will be mapped to this user.
	# Begin dialog box message
	/bin/echo "Successfully added $UPN to $currentUser."
	Message1="Successfully added $UPN to $currentUser."
    
	Message2="!!!YOUR ACTION IS REQUIRED!!!

Please remove and re-insert your smart card."
	Message3="!!!YOUR ACTION IS REQUIRED!!!

Click Continue to lock the screen.

Wait 10 seconds, then use your PIN to unlock the screen.

You may be prompted once for your keychain password after unlocking the screen."

	# End dialog box message
	/bin/echo "Creating AltSecurityIdentities for "$UPN""
	# Delete any axisting AltSecurityIdentities
	/usr/bin/dscl . -delete /Users/"$currentUser" AltSecurityIdentities
	# Create new AltSecurityIdentities
	/usr/bin/dscl . -create /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message1}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message2}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message3}\" with title \"Smart Card Mapping\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
	MarkPIVMandatoryYes
	/usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
    
#
#
fi
# /bin/echo "End ${FUNCNAME[0]}"
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

Check_For_nonValid_smart_card_Users

checkForSmartCard

EnableCTK

#Command to force a restart of USB services for some smart card readers
/usr/bin/killall - STOP usbd

IntroMessage

Check_for_PIV_Auth_Cert

if [[ "$sw_vers_Major_Integer" -gt 1015 ]]; then
	Test_Smart_Card_PIN
fi

checkForPaired

getUPN

createAltSecId

exit 0
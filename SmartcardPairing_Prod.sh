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
ImageFilePath="/Users/Shared/Management/Images/DHS.png"

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
    Message="A Smartcard is already paired with this Mac."
   	/bin/echo "${Message}"
    /usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Ok\"} default button 1"
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
Message="This will enable Smartcard login for this Mac.

Do NOT continue unless you know your PIN.

Please insert your Smartcard to begin."
#
/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
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
		/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
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
Message="Please enter your Smartcard PIN."
# /bin/echo "${Message}"
title="Department of Homeland Security"
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
	/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Cancel\" , \"Continue\"} default button 1 giving up after 30"
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
	/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\" , \"Cancel\"} default button 1"
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
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
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
	rv=$(/usr/bin/sudo -u "$currentUser" /usr/bin/osascript -e "display dialog \"${Message}\" with title \"Department of Homeland Security\" with icon POSIX file \"${ImageFilePath}\" buttons {\"Continue\"} default button 1")
	MarkPIVMandatoryYes
#
#
else

# Creating AltSecurityIdentities for the user
/bin/echo "Creating AltSecurityIdentities for $UPN"
/usr/bin/dscl . -delete /Users/"$currentUser" AltSecurityIdentities
/usr/bin/dscl . -create /Users/"$currentUser" AltSecurityIdentities Kerberos:"$UPN"
MarkPIVMandatoryYes
/usr/bin/dscl . -delete /Users/"$currentUser" SmartCardEnforcement
/bin/echo "AltSecurityIdentities created."

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

#exit 0

####################################################################################################
# 
# Start SmartCard Login Plist Process
#
####################################################################################################


# HARDCODED VALUE FOR "ExclusionGroupName" IS SET HERE
# Jamf Parameter Value Label - Smart Card Enforced Exclusion Group Name (default is smartcardexclusion)
ExclusionGroupName="smartcardexclusion"
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 4 AND, IF SO, ASSIGN TO "ExclusionGroupName"
# If a value is specified via a Jamf policy, it will override the hardcoded value in the script.
if [ "$4" != "" ];then
	ExclusionGroupName="$4"
fi
/bin/echo "ExclusionGroupName: ${ExclusionGroupName}"

# HARDCODED VALUE FOR "UsersToExclude" IS SET HERE
# Jamf Parameter Value Label - Users to exclude (separated by spaces)
UsersToExclude=""
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 5 AND, IF SO, ASSIGN TO "UsersToExclude"
# If a value is specificed via a Jamf policy, it will override the hardcoded value in the script.
if [ "$5" != "" ];then
    UsersToExclude=$5
fi
/bin/echo "UsersToExclude: ${UsersToExclude}"

# HARDCODED VALUE FOR "TrustedAuthoritiesHashes" IS SET HERE
# Jamf Parameter Value Label - TrustedAuthorities SHA-256 Hashes (separated by spaces)
TrustedAuthoritiesHashes=""
# CHECK TO SEE IF A VALUE WAS PASSED IN PARAMETER 6 AND, IF SO, ASSIGN TO "TrustedAuthoritiesHashes"
# If a value is specificed via a Jamf policy, it will override the hardcoded value in the script.
if [ "$6" != "" ];then
    TrustedAuthoritiesHashes=$6
fi
/bin/echo "TrustedAuthoritiesHashes: ${TrustedAuthoritiesHashes}"
TrustedAuthoritiesArray=(${TrustedAuthoritiesHashes})


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
  /bin/echo "This script must be run as root or sudo."
  exit 1
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Create SmartcardLogin.plist for Attribute Mapping ###
function createMapping (){
/bin/echo "Begin ${FUNCNAME[0]}"
#
/bin/cat > "/etc/SmartcardLogin.plist" << Attr_Mapping
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AttributeMapping</key>
	<dict>
		<key>dsAttributeString</key>
		<string>dsAttrTypeStandard:AltSecurityIdentities</string>
		<key>fields</key>
		<array>
			<string>NT Principal Name</string>
		</array>
		<key>formatString</key>
		<string>Kerberos:\$1</string>
	</dict>
	<key>NotEnforcedGroup</key>
	<string>${ExclusionGroupName}</string>
</dict>
</plist>
Attr_Mapping
#
/usr/sbin/chown root:wheel /etc/SmartcardLogin.plist
/bin/chmod 644 /etc/SmartcardLogin.plist
/bin/ls -al /etc/SmartcardLogin.plist
#
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### add TrustedAuthorities Array
function addTrustedAuthoritiesArray () {
/bin/echo "Begin ${FUNCNAME[0]}"
if [[ -z $(/usr/bin/defaults read /etc/SmartcardLogin.plist TrustedAuthorities 2> /dev/null) ]]; then
	/bin/echo "Adding TrustedAuthoritiesArray"
	/usr/libexec/PlistBuddy -c 'Add :TrustedAuthorities array' /etc/SmartcardLogin.plist
fi

for TrustedAuthority in "${TrustedAuthoritiesArray[@]}"
do
	/bin/echo "Adding TrustedAuthority ${TrustedAuthority}"
	/usr/libexec/PlistBuddy -c "Add :TrustedAuthorities: string ${TrustedAuthority}" /etc/SmartcardLogin.plist 
done
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Get available hidden GID  ###
function get_unused_hidden_gid () {
/bin/echo "Begin ${FUNCNAME[0]}"
availableHiddenGID=""
usedGIDs=($(/usr/bin/dscl . list /Groups PrimaryGroupID | /usr/bin/awk '{if($2<500){print $2}}' | /usr/bin/sort -rnu))
for availableHiddenGID in $(/usr/bin/seq 499 200); do
	[[ " ${usedGIDs[@]} " =~ " ${availableHiddenGID} " ]] && continue || echo $availableHiddenGID; break
done

/bin/echo "availableHiddenGID = $availableHiddenGID"

if [[ -z ${availableHiddenGID} ]]; then
	availableHiddenGID="499"
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Create Smart Card Enforced Exclusion Group  ###
function Create_Group () {
/bin/echo "Begin ${FUNCNAME[0]}"
currentGID=$(/usr/bin/dscacheutil -q group -a name ${ExclusionGroupName} 2> /dev/null | /usr/bin/awk '/gid/ {print $NF}')
/bin/echo "${ExclusionGroupName} GID is currently ${currentGID}"
if [[ -z ${currentGID} ]] || [[ ${currentGID} -gt 499 ]]; then
	/bin/echo "Creating/updating group $ExclusionGroupName."
	get_unused_hidden_gid
	/usr/sbin/dseditgroup -q -o delete ${ExclusionGroupName} >/dev/null 2>&1
	/usr/sbin/dseditgroup -q -o create -i ${availableHiddenGID} ${ExclusionGroupName}
	/bin/echo "${ExclusionGroupName} GID is now ${availableHiddenGID}"
else
	/bin/echo "Updating group $ExclusionGroupName."
	/bin/echo "${ExclusionGroupName} GID ${currentGID} is a hidden group. No need to change the GID."
	/usr/sbin/dseditgroup -q -o delete ${ExclusionGroupName} >/dev/null 2>&1
	/usr/sbin/dseditgroup -q -o create -i ${currentGID} ${ExclusionGroupName}
fi
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Populate Smart Card Enforced Exclusion Group  ###
function Populate_Group () {
/bin/echo "Begin ${FUNCNAME[0]}"
for EachUser in ${UsersToExclude} ;
do
	/bin/echo "Adding ${EachUser} to ${ExclusionGroupName}"
	/usr/sbin/dseditgroup -q -o edit -a "${EachUser}" -t user ${ExclusionGroupName}
done
# /bin/echo "End ${FUNCNAME[0]}"
}
###
#

####################################################################################################
# 
# SCRIPT CONTENTS
#
####################################################################################################

rootcheck

createMapping

if [[ ${TrustedAuthoritiesArray} ]] ; then
	addTrustedAuthoritiesArray
fi

Create_Group

Populate_Group

/usr/bin/defaults write /Library/Preferences/com.apple.security.smartcard allowUnmappedUsers -int 1

#exit 0

####################################################################################################
# 
# Start PAM Settings
#
####################################################################################################

#
PIVMandatory=$(/usr/bin/defaults read "/private/var/EnterpriseManagement/com.apple.enterprisedeployment" PIVMandatory)
#
####################################################################################################
#
# Functions to call on
#
####################################################################################################

#
### Ensure we are running this script as root ###
function rootcheck () {
/bin/echo "Begin ${FUNCNAME[0]}"
if [ "$(/usr/bin/whoami)" != "root" ] ; then
	/bin/echo "This script must be run as root or sudo."
	exit 1
fi
/bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Lock PAM to be PIV-Mandatory ###
function lockPAM () {
/bin/echo "Begin ${FUNCNAME[0]}"

# write out a new sudo file
/bin/cat > /etc/pam.d/sudo << SUDO_END
# sudo: auth account password session
auth        sufficient    pam_smartcard.so
auth        required      pam_opendirectory.so
auth        required      pam_deny.so
account     required      pam_permit.so
password    required      pam_deny.so
session     required      pam_permit.so
SUDO_END
# Fix new file ownership and permissions
/bin/chmod 444 /etc/pam.d/sudo
/usr/sbin/chown root:wheel /etc/pam.d/sudo

# write out a new login file
/bin/cat > /etc/pam.d/login << LOGIN_END
# login: auth account password session
auth        sufficient    pam_smartcard.so
auth        optional      pam_krb5.so use_kcminit
auth        optional      pam_ntlm.so try_first_pass
auth        optional      pam_mount.so try_first_pass
auth        required      pam_opendirectory.so try_first_pass
auth        required      pam_deny.so
account     required      pam_nologin.so
account     required      pam_opendirectory.so
password    required      pam_opendirectory.so
session     required      pam_launchd.so
session     required      pam_uwtmp.so
session     optional      pam_mount.so
LOGIN_END
# Fix new file ownership and permissions
/bin/chmod 644 /etc/pam.d/login
/usr/sbin/chown root:wheel /etc/pam.d/login

# write out a new su file
/bin/cat > /etc/pam.d/su << SU_END
# su: auth account password session
auth        sufficient    pam_smartcard.so
auth        required      pam_rootok.so
auth        required      pam_group.so no_warn group=admin,wheel ruser root_only fail_safe
account     required      pam_permit.so
account     required      pam_opendirectory.so no_check_shell
password    required      pam_opendirectory.so
session     required      pam_launchd.so
SU_END
# Fix new file ownership and permissions
/bin/chmod 644 /etc/pam.d/su
/usr/sbin/chown root:wheel /etc/pam.d/su

/bin/echo "End ${FUNCNAME[0]}"
}
###
#

#
### Unlock/Reset PAM to allow password ###
function unlockPAM () {
/bin/echo "Begin ${FUNCNAME[0]}"

# write out a new sudo file
/bin/cat > /etc/pam.d/sudo << SUDO_END
# sudo: auth account password session
auth       sufficient     pam_smartcard.so
auth       required       pam_opendirectory.so
account    required       pam_permit.so
password   required       pam_deny.so
session    required       pam_permit.so
SUDO_END

# Fix new file ownership and permissions
/bin/chmod 444 /etc/pam.d/sudo
/usr/sbin/chown root:wheel /etc/pam.d/sudo

# write out a new login file
/bin/cat > /etc/pam.d/login << LOGIN_END
# login: auth account password session
auth       optional       pam_krb5.so use_kcminit
auth       optional       pam_ntlm.so try_first_pass
auth       optional       pam_mount.so try_first_pass
auth       required       pam_opendirectory.so try_first_pass
account    required       pam_nologin.so
account    required       pam_opendirectory.so
password   required       pam_opendirectory.so
session    required       pam_launchd.so
session    required       pam_uwtmp.so
session    optional       pam_mount.so
LOGIN_END

# Fix new file ownership and permissions
/bin/chmod 644 /etc/pam.d/login
/usr/sbin/chown root:wheel /etc/pam.d/login

# write out a new su file
/bin/cat > /etc/pam.d/su << SU_END
# su: auth account session
auth       sufficient     pam_rootok.so
auth       required       pam_opendirectory.so
account    required       pam_group.so no_warn group=admin,wheel ruser root_only fail_safe
account    required       pam_opendirectory.so no_check_shell
password   required       pam_opendirectory.so
session    required       pam_launchd.so
SU_END

# Fix new file ownership and permissions
/bin/chmod 644 /etc/pam.d/su
/usr/sbin/chown root:wheel /etc/pam.d/su

/bin/echo "End ${FUNCNAME[0]}"
}
###
#

####################################################################################################
# 
# SCRIPT CONTENTS
#
####################################################################################################
rootcheck

if [ "$PIVMandatory" == "1" ] ; then
	/bin/echo "Lock PAM to be PIV-Mandatory"
	lockPAM
else
	/bin/echo "Unlock/Reset PAM to allow password"
	unlockPAM
fi

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

exit 0
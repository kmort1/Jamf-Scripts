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
#	Smartcard-CreateSmartcardLogin_plist.sh
#
# This script will create "/etc/SmartcardLogin.plist" for smart card login via AD kerberos caching.
# "man SmartCardServices" for the offline smart card login via kerberos caching example.
# This also adds support for the "NotEnforcedGroup" option in "/etc/SmartcardLogin.plist".
# Allowing a local group to be exempt from smart card enforcement.
#
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
####################################################################################################

# HARDCODED VALUES ARE SET HERE

# macOS Version
sw_vers_Full=$(/usr/bin/sw_vers -productVersion)
sw_vers_Full_Integer=$(/usr/bin/sw_vers -productVersion | /usr/bin/awk -F. '{for(i=1; i<=NF; i++) {printf("%02d",$i)}}')
sw_vers_Major=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f 1,2)
sw_vers_Major_Integer=$(/usr/bin/sw_vers -productVersion | /usr/bin/cut -d. -f 1,2 | /usr/bin/awk -F. '{for(i=1; i<=NF; i++) {printf("%02d",$i)}}')

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
/bin/echo "$computerName" is running macOS version "$sw_vers_Full"
#

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

exit 0

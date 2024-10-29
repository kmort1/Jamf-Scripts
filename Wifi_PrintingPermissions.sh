#!/bin/bash

# Workaround as shown in https://www.jamf.com/jamf-nation/discussions/19050/add-wifi-networks-without-admin-privileges
# Allows non-admin users to manage their WiFi configuration.

# WiFi Configuration Section
echo "=== WiFi Configuration ==="

echo "Updating authorization for system.preferences.network..."
/usr/bin/security authorizationdb write system.preferences.network allow
echo "Done: Updated system.preferences.network."

echo "Updating authorization for system.services.systemconfiguration.network..."
/usr/bin/security authorizationdb write system.services.systemconfiguration.network allow
echo "Done: Updated system.services.systemconfiguration.network."

echo "Updating authorization for com.apple.wifi..."
/usr/bin/security authorizationdb write com.apple.wifi allow
echo "Done: Updated com.apple.wifi."

echo "=========================="

# Printing Configuration Section
echo "=== Printing Configuration ==="

echo "Updating authorization for system.preferences.printing..."
/usr/bin/security authorizationdb write system.preferences.printing allow
echo "Done: Updated system.preferences.printing."

echo "Updating authorization for system.print.operator..."
/usr/bin/security authorizationdb write system.print.operator allow
echo "Done: Updated system.print.operator."

echo "=========================="

# Adding Users to lpadmin Group
echo "Adding everyone to the lpadmin group..."
/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
echo "Done: Added everyone to the lpadmin group."

echo "Adding everyone to the _lpadmin group..."
/usr/sbin/dseditgroup -o edit -n /Local/Default -a everyone -t group _lpadmin
echo "Done: Added everyone to the _lpadmin group."

exit 0

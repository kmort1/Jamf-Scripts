#!/bin/zsh


console_user=$(/usr/bin/stat -f "%Su" /dev/console)
adminCheck=$(dseditgroup -o checkmember -m $console_user admin)


if [[ $adminCheck == "no $console_user is NOT a member of admin" ]]; then
   echo "<result>"Standard"</result>"
elif [[ $adminCheck == "yes $console_user is a member of admin" ]]; then
   echo "<result>"Admin"</result>"
else
   echo "<result>"Unknown"</result>"
fi
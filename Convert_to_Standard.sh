#!/bin/sh

currentUser=$(ls -l /dev/console | awk '{ print $3 }')

      if [ $currentUser != "sifi" ]; then
        IsUserAdmin=$(id -G $currentUser| grep 80)
            if [ -n "$IsUserAdmin" ]; then
              /usr/sbin/dseditgroup -o edit -n /Local/Default -d $currentUser -t "user" "admin"
              exit 0
            else
                echo "$currentuser is not a local admin"
            fi
      fi
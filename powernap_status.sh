#!/bin/bash

# Get powrnap status
powernap_status=$(/usr/bin/pmset -g custom | /usr/bin/awk '/powernap/ { sum+=$2 } END {print sum}')

#Check is powernap is enabvled or disabled
if [[ "$powernap_status" != "0" ]]; then
    echo "<result>Enabled</result>"
else
    echo "<result>Disabled</result>"
fi
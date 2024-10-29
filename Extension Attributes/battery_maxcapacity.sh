#!/bin/sh

echo "<result>$(ioreg -r -c "AppleSmartBattery" | grep -o '"MaxCapacity"=[0-9]*' | cut -d '=' -f2 | head -n1)</result>"
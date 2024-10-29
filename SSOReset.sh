#!/bin/bash

# Stop the AppSSOAgent process
sudo pkill -9 AppSSOAgent

# Sleep for a few seconds to allow time for the process to terminate
sleep 3

# Start the AppSSOAgent process
sudo /System/Library/PrivateFrameworks/AppSSO.framework/Support/AppSSOAgent.app/Contents/MacOS/AppSSOAgent &

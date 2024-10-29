#!/bin/bash

# Paths to applications
acrobat_path="/Applications/Adobe Acrobat Reader.app"
acrobatpro_path="/Applications/Adobe Acrobat DC"
creative_cloud_path="/Applications/Adobe Creative Cloud"
creative_cloud_util_path="/Applications/Utilities/Adobe Creative Cloud"
app_manager_path="/Applications/Utilities/Adobe Application Manager"
installers_path="/Applications/Utilities/Adobe Installers"
sync_path="/Applications/Utilities/Adobe Sync"

# Function to remove an application
remove_app() {
    local app_path="$1"
    local app_name="$2"

    if [ -d "$app_path" ]; then
        rm -rf "$app_path"
        echo "$app_name has been removed."
    else
        echo "$app_name is not installed."
    fi
}

# Check and remove Adobe Acrobat Reader
remove_app "$acrobat_path" "Adobe Acrobat Reader"

# Check and remove Adobe Acrobat Reader
remove_app "$acrobatpro_path" "Adobe Acrobat Pro"

# Check and remove Adobe Creative Cloud
remove_app "$creative_cloud_path" "Adobe Creative Cloud"

# Check and remove Adobe Creative Cloud
remove_app "$creative_cloud_util_path" "Adobe Creative Cloud Ultilities"

# Check and remove Adobe Application Manager
remove_app "$app_manager_path" "Adobe Application Manager"

# Check and remove Adobe Installers
remove_app "$installers_path" "Adobe Installers"

# Check and remove Adobe Sync
remove_app "$sync_path" "Adobe Sync"

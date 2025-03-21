#!/bin/bash
# Version 2.0.7

#########################################################################################
# License information
#########################################################################################
# Copyright 2018 Jamf Professional Services

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

#########################################################################################
# General Information
#########################################################################################
# This script is designed to make implementation of DEPNotify very easy with limited
# scripting knowledge. The section below has variables that may be modified to customize
# the end user experience. DO NOT modify things in or below the CORE LOGIC area unless
# major testing and validation is performed.

# More information at: https://github.com/jamfprofessionalservices/DEP-Notify

#########################################################################################
# Testing Mode
#########################################################################################
# Testing flag will enable the following things to change:
# Auto removal of BOM files to reduce errors
# Sleep commands instead of policies or other changes being called
# Quit Key set to command + control + x
  TESTING_MODE=true # Set variable to true or false

#########################################################################################
# General Appearance
#########################################################################################
# Flag the app to open fullscreen or as a window
  FULLSCREEN=true # Set variable to true or false

# Banner image can be 600px wide by 100px high. Images will be scaled to fit
# If this variable is left blank, the generic image will appear. If using custom Self
# Service branding, please see the Customized Self Service Branding area below
  BANNER_IMAGE_PATH="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"

# Update the variable below replacing "Organization" with the actual name of your organization. Example "ACME Corp Inc."
  ORG_NAME="U.S. Department of Homeland Security"

# Main heading that will be displayed under the image
# If this variable is left blank, the generic banner will appear
  BANNER_TITLE="Welcome to $ORG_NAME"
	
# Update the variable below replacing "email helpdesk@company.com" with the actual plaintext instructions for your organization. Example "call 555-1212" or "email helpdesk@company.com"
  SUPPORT_CONTACT_DETAILS="itsupport@hq.dhs.gov"
  
# Paragraph text that will display under the main heading. For a new line, use \n
# If this variable is left blank, the generic message will appear. Leave single
# quotes below as double quotes will break the new lines.
  MAIN_TEXT='Thank you for choosing a Mac at the '$ORG_NAME'! We want you to have a few applications and settings configured before you get started with your new Mac. This process should take 20 to 30 minutes to complete. \n \n If you need additional software or help, please visit the Self Service app in your Applications folder or on your Dock.'

# Initial Start Status text that shows as things are firing up
  INITAL_START_STATUS="Initial Configuration Starting..."

# Text that will display in the progress bar
  INSTALL_COMPLETE_TEXT="Configuration Complete!"

# Complete messaging to the end user can ether be a button at the bottom of the
# app with a modification to the main window text or a dropdown alert box. Default
# value set to false and will use buttons instead of dropdown messages.
  COMPLETE_METHOD_DROPDOWN_ALERT=false # Set variable to true or false

# Script designed to automatically logout user to start FileVault process if
# deferred enablement is detected. Text displayed if deferred status is on.
  # Option for dropdown alert box
    FV_ALERT_TEXT="Your Mac must logout to start the encryption process. You will be asked to enter your password and click OK or Continue a few times. Your Mac will be usable while encryption takes place."
  # Options if not using dropdown alert box
    FV_COMPLETE_MAIN_TEXT='Your Mac must logout to start the encryption process. You will be asked to enter your password and click OK or Continue a few times. Your Mac will be usable while encryption takes place.'
    FV_COMPLETE_BUTTON_TEXT="Logout"

# Text that will display inside the alert once policies have finished
  # Option for dropdown alert box
    COMPLETE_ALERT_TEXT="Your Mac is now finished with initial setup and configuration. Press Quit to get started!"
  # Options if not using dropdown alert box
    COMPLETE_MAIN_TEXT='Your Mac is now finished with initial setup and configuration.'
    COMPLETE_BUTTON_TEXT="Get Started!"

#########################################################################################
# Plist Configuration
#########################################################################################
# The menu.depnotify.plist contains more and more things that configure the DEPNotify app
# You may want to save the file for purposes like verifying EULA acceptance or validating
# other options.

# Plist Save Location
  # This wrapper allows variables that are created later to be used but also allow for
  # configuration of where the plist is stored
    INFO_PLIST_WRAPPER (){
      DEP_NOTIFY_USER_INPUT_PLIST="/Users/$CURRENT_USER/Library/Preferences/menu.nomad.DEPNotifyUserInput.plist"
    }

# Status Text Alignment
  # The status text under the progress bar can be configured to be left, right, or center
    STATUS_TEXT_ALIGN="center"

# Help Button Configuration
  # The help button was changed to a popup. Button will appear if title is populated.
    HELP_BUBBLE_TITLE="Need Help?"
    HELP_BUBBLE_BODY="This tool at $ORG_NAME is designed to help with new employee onboarding. If you have issues, please $SUPPORT_CONTACT_DETAILS"

#########################################################################################
# Error Screen Text
#########################################################################################
# If testing mode is false and configuration files are present, this text will appear to
# the end user and asking them to contact IT. Limited window options here as the
# assumption is that they need to call IT. No continue or exit buttons will show for
# DEP Notify window and it will not show in fullscreen. IT staff will need to use Terminal
# or Activity Monitor to kill DEP Notify.

# Main heading that will be displayed under the image
  ERROR_BANNER_TITLE="Uh oh, Something Needs Fixing!"

# Paragraph text that will display under the main heading. For a new line, use \n
# If this variable is left blank, the generic message will appear. Leave single
# quotes below as double quotes will break the new lines.
	ERROR_MAIN_TEXT='We are sorry that you are experiencing this inconvenience with your new Mac. However, we have the nerds to get you back up and running in no time! \n \n Please contact IT right away and we will take a look at your computer ASAP. \n \n'	
	ERROR_MAIN_TEXT="$ERROR_MAIN_TEXT $SUPPORT_CONTACT_DETAILS"	
	  
# Error status message that is displayed under the progress bar
  ERROR_STATUS="Setup Failed"

#########################################################################################
# Trigger to be used to call the policy
#########################################################################################
# Policies can be called be either a custom trigger or by policy id.
# Select either event, to call the policy by the custom trigger,
# or id to call the policy by id.
TRIGGER="id"


#########################################################################################
# Policy Variable to Modify
#########################################################################################
# The policy array must be formatted "Progress Bar text,customTrigger". These will be
# run in order as they appear below.
  POLICY_ARRAY=(
    
    "Installing Rosetta 2,52"
    "Installing Identiv,43"
    "Installing Microsoft Company Portal,9"
    "Installing CrowdStrike,3"
    "Installing Microsoft Teams,34"
    "Installing OneDrive,19"
    "Installing Microsoft 365,177"
    "Installing Microsoft Edge,7"
    "Installing Citrix Workspace,56"
    "Installing Nessus,14"
    "Installing DisplayLink,31"
    "Installing Adobe Acrobat,35"
    "Setting Outlook as Default Mail Client,4"
    "Performing NIST Security Baseline,59"
    "Setting Default Dock,79"
    "Enabling FileVault,62"
    "Running Inventory,1"
    
    )

#########################################################################################
# Caffeinate / No Sleep Configuration
#########################################################################################
# Flag script to keep the computer from sleeping. BE VERY CAREFUL WITH THIS FLAG!
# This flag could expose your data to risk by leaving an unlocked computer wide open.
# Only recommended if you are using fullscreen mode and have a logout taking place at
# the end of configuration (like for FileVault). Some folks may use this in workflows
# where IT staff are the primary people setting up the device. The device will be
# allowed to sleep again once the DEPNotify app is quit as caffeinate is looking
# at DEPNotify's process ID.
  NO_SLEEP=true

#########################################################################################
# Customized Self Service Branding
#########################################################################################
# Flag for using the custom branding icon from Self Service and Jamf Pro
# This will override the banner image specified above. If you have changed the
# name of Self Service, make sure to modify the Self Service name below.
# Please note, custom branding is downloaded from Jamf Pro after Self Service has opened
# at least one time. The script is designed to wait until the files have been downloaded.
# This could take a few minutes depending on server and network resources.
  SELF_SERVICE_CUSTOM_BRANDING=true # Set variable to true or false

# If using a name other than Self Service with Custom branding. Change the
# name with the SELF_SERVICE_APP_NAME variable below. Keep .app on the end
  SELF_SERVICE_APP_NAME="Self Service.app"
  
# Number of seconds to wait (seconds) for the Self Service custon icon.
  SELF_SERVICE_CUSTOM_WAIT=20


#########################################################################################
# EULA Variables to Modify
#########################################################################################
# EULA configuration
  EULA_ENABLED=false # Set variable to true or false

  # EULA status bar text
    EULA_STATUS="Waiting on completion of EULA acceptance"

  # EULA button text on the main screen
    EULA_BUTTON="Read and Agree to EULA"

  # EULA Screen Title
    EULA_MAIN_TITLE="Organization End User License Agreement"

  # EULA Subtitle
    EULA_SUBTITLE="Please agree to the following terms and conditions to start configuration of this Mac"

  # Path to the EULA file you would like the user to read and agree to. It is
  # best to package this up with Composer or another tool and deliver it to a
  # shared area like /Users/Shared/
    EULA_FILE_PATH="/Users/Shared/eula.txt"

#########################################################################################
# Registration Variables to Modify
#########################################################################################
# Registration window configuration
  REGISTRATION_ENABLED=true # Set variable to true or false

  # Registration window title
    REGISTRATION_TITLE="Register Mac for U.S. Department of Homeland Security"
    
  # Registration status bar text
    REGISTRATION_STATUS="Waiting on completion of computer registration"

  # Registration window submit or finish button text
    REGISTRATION_BUTTON="Register"

  # The text and pick list sections below will write the following lines out for
  # end users. Use the variables below to configure what the sentence says
  # Ex: Setting Computer Name to macBook0132
    REGISTRATION_BEGIN_WORD="Setting"
    REGISTRATION_MIDDLE_WORD="to"

  # Registration window can have up to two text fields. Leaving the text display
  # variable empty will hide the input box. Display text is to the side of the
  # input and placeholder text is the gray text inside the input box.
  # Registration window can have up to four dropdown / pick list inputs. Leaving
  # the pick display variable empty will hide the dropdown / pick list.

  # First Text Field
  #######################################################################################
    # Text Field Label
      REG_TEXT_LABEL_1="Full Name"

    # Place Holder Text
      REG_TEXT_LABEL_1_PLACEHOLDER="John Appleseed"

    # Optional flag for making the field an optional input for end user
      REG_TEXT_LABEL_1_OPTIONAL="false" # Set variable to true or false

    # Help Bubble for Input. If title left blank, this will not appear
      REG_TEXT_LABEL_1_HELP_TITLE="User's Full Name"
      REG_TEXT_LABEL_1_HELP_TEXT="This field associates your name with your new Mac. This is important for inventory purposes."

    # Logic below was put in this section rather than in core code as folks may
    # want to change what the field does. This is a function that gets called
    # when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
      REG_TEXT_LABEL_1_LOGIC (){
        REG_TEXT_LABEL_1_VALUE=$(/usr/bin/defaults read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_TEXT_LABEL_1")
        if [ "$REG_TEXT_LABEL_1_OPTIONAL" = true ] && [ "$REG_TEXT_LABEL_1_VALUE" = "" ]; then
          echo "Status: $REG_TEXT_LABEL_1 was left empty. Skipping..." >> "$DEP_NOTIFY_LOG"
          echo "$(date "+%a %h %d %H:%M:%S"): $REG_TEXT_LABEL_1 was set to optional and was left empty. Skipping..." >> "$DEP_NOTIFY_DEBUG"
          sleep 5
        else
          echo "Status: $REGISTRATION_BEGIN_WORD $REG_TEXT_LABEL_1 $REGISTRATION_MIDDLE_WORD $REG_TEXT_LABEL_1_VALUE" >> "$DEP_NOTIFY_LOG"
          if [ "$TESTING_MODE" = true ]; then
            sleep 10
          else
            "$JAMF_BINARY" recon -realname "$REG_TEXT_LABEL_1_VALUE"
            sleep 5
          fi
        fi
      }

  # Second Text Field
  #######################################################################################
    # Text Field Label
      REG_TEXT_LABEL_2="User Email"

    # Place Holder Text
      REG_TEXT_LABEL_2_PLACEHOLDER="johnappleseed@hq.dhs.gov"

    # Optional flag for making the field an optional input for end user
      REG_TEXT_LABEL_2_OPTIONAL="false" # Set variable to true or false

    # Help Bubble for Input. If title left blank, this will not appear
      REG_TEXT_LABEL_2_HELP_TITLE="Email Field"
      REG_TEXT_LABEL_2_HELP_TEXT="This field associates your email with your new Mac. This is important for inventory purposes."

    # Logic below was put in this section rather than in core code as folks may
    # want to change what the field does. This is a function that gets called
    # when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
      REG_TEXT_LABEL_2_LOGIC (){
        REG_TEXT_LABEL_2_VALUE=$(/usr/bin/defaults read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_TEXT_LABEL_2")
        if [ "$REG_TEXT_LABEL_2_OPTIONAL" = true ] && [ "$REG_TEXT_LABEL_2_VALUE" = "" ]; then
          echo "Status: $REG_TEXT_LABEL_2 was left empty. Skipping..." >> "$DEP_NOTIFY_LOG"
          echo "$(date "+%a %h %d %H:%M:%S"): $REG_TEXT_LABEL_2 was set to optional and was left empty. Skipping..." >> "$DEP_NOTIFY_DEBUG"
          sleep 5
        else
          echo "Status: $REGISTRATION_BEGIN_WORD $REG_TEXT_LABEL_2 $REGISTRATION_MIDDLE_WORD $REG_TEXT_LABEL_2_VALUE" >> "$DEP_NOTIFY_LOG"
          if [ "$TESTING_MODE" = true ]; then
             sleep 10
          else
            "$JAMF_BINARY" recon -email "$REG_TEXT_LABEL_2_VALUE"
          fi
        fi
      }

  # Popup 1
  #######################################################################################
    # Label for the popup
      REG_POPUP_LABEL_1=""

    # Array of options for the user to select
      REG_POPUP_LABEL_1_OPTIONS=(
        "Amsterdam"
        "Katowice"
        "Eau Claire"
        "Minneapolis"
      )

    # Help Bubble for Input. If title left blank, this will not appear
      REG_POPUP_LABEL_1_HELP_TITLE="Building Dropdown Field"
      REG_POPUP_LABEL_1_HELP_TEXT="Please choose the appropriate building for where you normally work. This is important for inventory purposes."

    # Logic below was put in this section rather than in core code as folks may
    # want to change what the field does. This is a function that gets called
    # when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
      REG_POPUP_LABEL_1_LOGIC (){
        REG_POPUP_LABEL_1_VALUE=$(/usr/bin/defaults read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_1")
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_1 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_1_VALUE" >> "$DEP_NOTIFY_LOG"
        if [ "$TESTING_MODE" = true ]; then
           sleep 10
        else
          "$JAMF_BINARY" recon -building "$REG_POPUP_LABEL_1_VALUE"
        fi
      }

  # Popup 2
  #######################################################################################
    # Label for the popup
      REG_POPUP_LABEL_2=""

    # Array of options for the user to select
      REG_POPUP_LABEL_2_OPTIONS=(

      )

    # Help Bubble for Input. If title left blank, this will not appear
      REG_POPUP_LABEL_2_HELP_TITLE="Department Dropdown Field"
      REG_POPUP_LABEL_2_HELP_TEXT="Please choose the appropriate department for where you normally work. This is important for inventory purposes."

    # Logic below was put in this section rather than in core code as folks may
    # want to change what the field does. This is a function that gets called
    # when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
      REG_POPUP_LABEL_2_LOGIC (){
        REG_POPUP_LABEL_2_VALUE=$(/usr/bin/defaults read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_2")
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_2 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_2_VALUE" >> "$DEP_NOTIFY_LOG"
        if [ "$TESTING_MODE" = true ]; then
           sleep 10
        else
          "$JAMF_BINARY" recon -department "$REG_POPUP_LABEL_2_VALUE"
        fi
      }

  # Popup 3 - Code is here but currently unused
  #######################################################################################
    # Label for the popup
      REG_POPUP_LABEL_3=""

    # Array of options for the user to select
      REG_POPUP_LABEL_3_OPTIONS=(

      )

    # Help Bubble for Input. If title left blank, this will not appear
      REG_POPUP_LABEL_3_HELP_TITLE="Dropdown 3 Field"
      REG_POPUP_LABEL_3_HELP_TEXT="This dropdown is currently not in use. All code is here ready for you to use. It can also be hidden by removing the contents of the REG_POPUP_LABEL_3 variable."

    # Logic below was put in this section rather than in core code as folks may
    # want to change what the field does. This is a function that gets called
    # when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
      REG_POPUP_LABEL_3_LOGIC (){
        REG_POPUP_LABEL_3_VALUE=$(/usr/bin/defaults read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_3")
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_3 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_3_VALUE" >> "$DEP_NOTIFY_LOG"
        if [ "$TESTING_MODE" = true ]; then
          sleep 10
        else
          sleep 10
        fi
      }

  # Popup 4 - Code is here but currently unused
  #######################################################################################
    # Label for the popup
      REG_POPUP_LABEL_4=""

    # Array of options for the user to select
      REG_POPUP_LABEL_4_OPTIONS=(

      )

    # Help Bubble for Input. If title left blank, this will not appear
      REG_POPUP_LABEL_4_HELP_TITLE="Dropdown 4 Field"
      REG_POPUP_LABEL_4_HELP_TEXT="This dropdown is currently not in use. All code is here ready for you to use. It can also be hidden by removing the contents of the REG_POPUP_LABEL_4 variable."

    # Logic below was put in this section rather than in core code as folks may
    # want to change what the field does. This is a function that gets called
    # when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
      REG_POPUP_LABEL_4_LOGIC (){
        REG_POPUP_LABEL_4_VALUE=$(/usr/bin/defaults read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_4")
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_4 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_4_VALUE" >> "$DEP_NOTIFY_LOG"
        if [ "$TESTING_MODE" = true ]; then
          sleep 10
        else
          sleep 10
        fi
      }

#########################################################################################
#########################################################################################
# Core Script Logic - Don't Change Without Major Testing
#########################################################################################
#########################################################################################

# Variables for File Paths
  JAMF_BINARY="/usr/local/bin/jamf"
  FDE_SETUP_BINARY="/usr/bin/fdesetup"
  DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"
  DEP_NOTIFY_LOG="/var/tmp/depnotify.log"
  DEP_NOTIFY_DEBUG="/var/tmp/depnotifyDebug.log"
  DEP_NOTIFY_DONE="/var/tmp/com.depnotify.provisioning.done"

# Pulling from Policy parameters to allow true/false flags to be set. More info
# can be found on https://www.jamf.com/jamf-nation/articles/146/script-parameters
# These will override what is specified in the script above.
  # Testing Mode
    if [ "$4" != "" ]; then TESTING_MODE="$4"; fi
  # Fullscreen Mode
    if [ "$5" != "" ]; then FULLSCREEN="$5"; fi
  # No Sleep / Caffeinate Mode
    if [ "$6" != "" ]; then NO_SLEEP="$6"; fi
  # Self Service Custom Branding
    if [ "$7" != "" ]; then SELF_SERVICE_CUSTOM_BRANDING="$7"; fi
  # Complete method dropdown or main screen
    if [ "$8" != "" ]; then COMPLETE_METHOD_DROPDOWN_ALERT="$8"; fi
  # EULA Mode
    if [ "$9" != "" ]; then EULA_ENABLED="$9"; fi
  # Registration Mode
    if [ "${10}" != "" ]; then REGISTRATION_ENABLED="${10}"; fi

# Standard Testing Mode Enhancements
  if [ "$TESTING_MODE" = true ]; then
    # Removing old config file if present (Testing Mode Only)
      if [ -f "$DEP_NOTIFY_LOG" ]; then rm "$DEP_NOTIFY_LOG"; fi
      if [ -f "$DEP_NOTIFY_DONE" ]; then rm "$DEP_NOTIFY_DONE"; fi
      if [ -f "$DEP_NOTIFY_DEBUG" ]; then rm "$DEP_NOTIFY_DEBUG"; fi
    # Setting Quit Key set to command + control + x (Testing Mode Only)
      echo "Command: QuitKey: x" >> "$DEP_NOTIFY_LOG"
  fi

# Validating true/false flags
  if [ "$TESTING_MODE" != true ] && [ "$TESTING_MODE" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Testing configuration not set properly. Currently set to $TESTING_MODE. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$FULLSCREEN" != true ] && [ "$FULLSCREEN" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Fullscreen configuration not set properly. Currently set to $FULLSCREEN. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$NO_SLEEP" != true ] && [ "$NO_SLEEP" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Sleep configuration not set properly. Currently set to $NO_SLEEP. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$SELF_SERVICE_CUSTOM_BRANDING" != true ] && [ "$SELF_SERVICE_CUSTOM_BRANDING" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Self Service Custom Branding configuration not set properly. Currently set to $SELF_SERVICE_CUSTOM_BRANDING. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != true ] && [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Completion alert method not set properly. Currently set to $COMPLETE_METHOD_DROPDOWN_ALERT. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$EULA_ENABLED" != true ] && [ "$EULA_ENABLED" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): EULA configuration not set properly. Currently set to $EULA_ENABLED. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$REGISTRATION_ENABLED" != true ] && [ "$REGISTRATION_ENABLED" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Registration configuration not set properly. Currently set to $REGISTRATION_ENABLED. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi

# Run DEP Notify will run after Apple Setup Assistant
  SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
  until [ "$SETUP_ASSISTANT_PROCESS" = "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Setup Assistant Still Running. PID $SETUP_ASSISTANT_PROCESS." >> "$DEP_NOTIFY_DEBUG"
    sleep 1
    SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
  done

# Checking to see if the Finder is running now before continuing. This can help
# in scenarios where an end user is not configuring the device.
  FINDER_PROCESS=$(pgrep -l "Finder")
  until [ "$FINDER_PROCESS" != "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen." >> "$DEP_NOTIFY_DEBUG"
    sleep 1
    FINDER_PROCESS=$(pgrep -l "Finder")
  done

# After the Apple Setup completed. Now safe to grab the current user and user ID
  CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console)
  CURRENT_USER_ID=$(id -u $CURRENT_USER)
  echo "$(date "+%a %h %d %H:%M:%S"): Current user set to $CURRENT_USER (id: $CURRENT_USER_ID)." >> "$DEP_NOTIFY_DEBUG"

# Stop DEPNotify if there was already a DEPNotify window running (from a PreStage package postinstall script).
 PREVIOUS_DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
  until [ "$PREVIOUS_DEP_NOTIFY_PROCESS" = "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Stopping the previously-opened instance of DEPNotify." >> "$DEP_NOTIFY_DEBUG"
    kill $PREVIOUS_DEP_NOTIFY_PROCESS
    PREVIOUS_DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
  done
  
 # Stop BigHonkingText if it's running (from a PreStage package postinstall script).
 BIG_HONKING_TEXT_PROCESS=$(pgrep -l "BigHonkingText" | cut -d " " -f1)
  until [ "$BIG_HONKING_TEXT_PROCESS" = "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Stopping the previously-opened instance of BigHonkingText." >> "$DEP_NOTIFY_DEBUG"
    kill $BIG_HONKING_TEXT_PROCESS
    BIG_HONKING_TEXT_PROCESS=$(pgrep -l "BigHonkingText" | cut -d " " -f1)
  done
 
# Adding Check and Warning if Testing Mode is off and BOM files exist
  if [[ ( -f "$DEP_NOTIFY_LOG" || -f "$DEP_NOTIFY_DONE" ) && "$TESTING_MODE" = false ]]; then
    echo "$(date "+%a %h %d %H:%M:%S"): TESTING_MODE set to false but config files were found in /var/tmp. Letting user know and exiting." >> "$DEP_NOTIFY_DEBUG"
    mv "$DEP_NOTIFY_LOG" "/var/tmp/depnotify_old.log"
    echo "Command: MainTitle: $ERROR_BANNER_TITLE" >> "$DEP_NOTIFY_LOG"
    echo "Command: MainText: $ERROR_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
    echo "Status: $ERROR_STATUS" >> "$DEP_NOTIFY_LOG"
##    sudo -u "$CURRENT_USER" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
    launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
    sleep 5
    exit 1
  fi

# If SELF_SERVICE_CUSTOM_BRANDING is set to true. Loading the updated icon
  if [ "$SELF_SERVICE_CUSTOM_BRANDING" = true ]; then
    open -a "/Applications/$SELF_SERVICE_APP_NAME" --hide

  # Loop waiting on the branding image to properly show in the users library
	SELF_SERVICE_COUNTER=0
	CUSTOM_BRANDING_PNG="/Users/$CURRENT_USER/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
	
	until [ -f "$CUSTOM_BRANDING_PNG" ]; do
		echo "$(date "+%a %h %d %H:%M:%S"): Waiting for branding image from Jamf Pro." >> "$DEP_NOTIFY_DEBUG"
		sleep 1
		(( SELF_SERVICE_COUNTER++ ))
		if [ $SELF_SERVICE_COUNTER -gt $SELF_SERVICE_CUSTOM_WAIT ];then
		   CUSTOM_BRANDING_PNG="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"
		   break
		fi
	done

  # Setting Banner Image for DEP Notify to Self Service Custom Branding
    BANNER_IMAGE_PATH="$CUSTOM_BRANDING_PNG"

  # Closing Self Service
    SELF_SERVICE_PID=$(pgrep -l "Self Service" | cut -d' ' -f1)
    echo "$(date "+%a %h %d %H:%M:%S"): Self Service custom branding icon has been loaded. Killing Self Service PID $SELF_SERVICE_PID." >> "$DEP_NOTIFY_DEBUG"
    kill "$SELF_SERVICE_PID"
  elif [ ! -f "$BANNER_IMAGE_PATH" ];then
    BANNER_IMAGE_PATH="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"
  fi

# Setting custom image if specified
  if [ "$BANNER_IMAGE_PATH" != "" ]; then  echo "Command: Image: $BANNER_IMAGE_PATH" >> "$DEP_NOTIFY_LOG"; fi

# Setting custom title if specified
  if [ "$BANNER_TITLE" != "" ]; then echo "Command: MainTitle: $BANNER_TITLE" >> "$DEP_NOTIFY_LOG"; fi

# Setting custom main text if specified
  if [ "$MAIN_TEXT" != "" ]; then echo "Command: MainText: $MAIN_TEXT" >> "$DEP_NOTIFY_LOG"; fi

# General Plist Configuration
  # Calling function to set the INFO_PLIST_PATH
    INFO_PLIST_WRAPPER

  # The plist information below
    DEP_NOTIFY_CONFIG_PLIST="/Users/$CURRENT_USER/Library/Preferences/menu.nomad.DEPNotify.plist"

  # If testing mode is on, this will remove some old configuration files
    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_CONFIG_PLIST" ]; then rm "$DEP_NOTIFY_CONFIG_PLIST"; fi
    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_USER_INPUT_PLIST" ]; then rm "$DEP_NOTIFY_USER_INPUT_PLIST"; fi

  # Setting default path to the plist which stores all the user completed info
    /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" pathToPlistFile "$DEP_NOTIFY_USER_INPUT_PLIST"

  # Setting status text alignment
    /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" statusTextAlignment "$STATUS_TEXT_ALIGN"

  # Setting help button
    if [ "$HELP_BUBBLE_TITLE" != "" ]; then
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" helpBubble -array-add "$HELP_BUBBLE_TITLE"
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" helpBubble -array-add "$HELP_BUBBLE_BODY"
    fi

# EULA Configuration
  if [ "$EULA_ENABLED" =  true ]; then
    DEP_NOTIFY_EULA_DONE="/var/tmp/com.depnotify.agreement.done"

    # If testing mode is on, this will remove EULA specific configuration files
      if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_EULA_DONE" ]; then rm "$DEP_NOTIFY_EULA_DONE"; fi

    # Writing title, subtitle, and EULA txt location to plist
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" EULAMainTitle "$EULA_MAIN_TITLE"
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" EULASubTitle "$EULA_SUBTITLE"
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" pathToEULA "$EULA_FILE_PATH"

    # Setting ownership of EULA file
      chown "$CURRENT_USER:staff" "$EULA_FILE_PATH"
      chmod 444 "$EULA_FILE_PATH"
  fi

# Registration Plist Configuration
  if [ "$REGISTRATION_ENABLED" = true ]; then
    DEP_NOTIFY_REGISTER_DONE="/var/tmp/com.depnotify.registration.done"

    # If testing mode is on, this will remove registration specific configuration files
      if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_REGISTER_DONE" ]; then rm "$DEP_NOTIFY_REGISTER_DONE"; fi

    # Main Window Text Configuration
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" registrationMainTitle "$REGISTRATION_TITLE"
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" registrationButtonLabel "$REGISTRATION_BUTTON"
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" registrationPicturePath "$BANNER_IMAGE_PATH"

    # First Text Box Configuration
      if [ "$REG_TEXT_LABEL_1" != "" ]; then
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField1Label "$REG_TEXT_LABEL_1"
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField1Placeholder "$REG_TEXT_LABEL_1_PLACEHOLDER"
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField1IsOptional "$REG_TEXT_LABEL_1_OPTIONAL"
        # Code for showing the help box if configured
          if [ "$REG_TEXT_LABEL_1_HELP_TITLE" != "" ]; then
              /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField1Bubble -array-add "$REG_TEXT_LABEL_1_HELP_TITLE"
              /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField1Bubble -array-add "$REG_TEXT_LABEL_1_HELP_TEXT"
          fi
      fi

    # Second Text Box Configuration
      if [ "$REG_TEXT_LABEL_2" != "" ]; then
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField2Label "$REG_TEXT_LABEL_2"
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField2Placeholder "$REG_TEXT_LABEL_2_PLACEHOLDER"
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField2IsOptional "$REG_TEXT_LABEL_2_OPTIONAL"
        # Code for showing the help box if configured
          if [ "$REG_TEXT_LABEL_2_HELP_TITLE" != "" ]; then
              /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField2Bubble -array-add "$REG_TEXT_LABEL_2_HELP_TITLE"
              /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" textField2Bubble -array-add "$REG_TEXT_LABEL_2_HELP_TEXT"
          fi
      fi

    # Popup 1
      if [ "$REG_POPUP_LABEL_1" != "" ]; then
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton1Label "$REG_POPUP_LABEL_1"
        # Code for showing the help box if configured
          if [ "$REG_POPUP_LABEL_1_HELP_TITLE" != "" ]; then
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu1Bubble -array-add "$REG_POPUP_LABEL_1_HELP_TITLE"
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu1Bubble -array-add "$REG_POPUP_LABEL_1_HELP_TEXT"
          fi
        # Code for adding the items from the array above into the plist
          for REG_POPUP_LABEL_1_OPTION in "${REG_POPUP_LABEL_1_OPTIONS[@]}"; do
             /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton1Content -array-add "$REG_POPUP_LABEL_1_OPTION"
          done
      fi

    # Popup 2
      if [ "$REG_POPUP_LABEL_2" != "" ]; then
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton2Label "$REG_POPUP_LABEL_2"
        # Code for showing the help box if configured
          if [ "$REG_POPUP_LABEL_2_HELP_TITLE" != "" ]; then
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu2Bubble -array-add "$REG_POPUP_LABEL_2_HELP_TITLE"
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu2Bubble -array-add "$REG_POPUP_LABEL_2_HELP_TEXT"
          fi
        # Code for adding the items from the array above into the plist
          for REG_POPUP_LABEL_2_OPTION in "${REG_POPUP_LABEL_2_OPTIONS[@]}"; do
             /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton2Content -array-add "$REG_POPUP_LABEL_2_OPTION"
          done
      fi

    # Popup 3
      if [ "$REG_POPUP_LABEL_3" != "" ]; then
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton3Label "$REG_POPUP_LABEL_3"
        # Code for showing the help box if configured
          if [ "$REG_POPUP_LABEL_3_HELP_TITLE" != "" ]; then
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu3Bubble -array-add "$REG_POPUP_LABEL_3_HELP_TITLE"
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu3Bubble -array-add "$REG_POPUP_LABEL_3_HELP_TEXT"
          fi
        # Code for adding the items from the array above into the plist
          for REG_POPUP_LABEL_3_OPTION in "${REG_POPUP_LABEL_3_OPTIONS[@]}"; do
             /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton3Content -array-add "$REG_POPUP_LABEL_3_OPTION"
          done
      fi

    # Popup 4
      if [ "$REG_POPUP_LABEL_4" != "" ]; then
        /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton4Label "$REG_POPUP_LABEL_4"
        # Code for showing the help box if configured
          if [ "$REG_POPUP_LABEL_4_HELP_TITLE" != "" ]; then
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu4Bubble -array-add "$REG_POPUP_LABEL_4_HELP_TITLE"
            /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupMenu4Bubble -array-add "$REG_POPUP_LABEL_4_HELP_TEXT"
          fi
        # Code for adding the items from the array above into the plist
          for REG_POPUP_LABEL_4_OPTION in "${REG_POPUP_LABEL_4_OPTIONS[@]}"; do
             /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" popupButton4Content -array-add "$REG_POPUP_LABEL_4_OPTION"
          done
      fi
  fi

# Changing Ownership of the plist file
  chown "$CURRENT_USER":staff "$DEP_NOTIFY_CONFIG_PLIST"
  chmod 600 "$DEP_NOTIFY_CONFIG_PLIST"

# Opening the app after initial configuration
  if [ "$FULLSCREEN" = true ]; then
##    sudo -u "$CURRENT_USER" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG" -fullScreen
    launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG" -fullScreen
  elif [ "$FULLSCREEN" = false ]; then
##    sudo -u "$CURRENT_USER" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
    launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
  fi

# Grabbing the DEP Notify Process ID for use later
  DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
  until [ "$DEP_NOTIFY_PROCESS" != "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Waiting for DEPNotify to start to gather the process ID." >> "$DEP_NOTIFY_DEBUG"
    sleep 1
    DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
  done

# Using Caffeinate binary to keep the computer awake if enabled
  if [ "$NO_SLEEP" = true ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Caffeinating DEP Notify process. Process ID: $DEP_NOTIFY_PROCESS" >> "$DEP_NOTIFY_DEBUG"
    caffeinate -disu -w "$DEP_NOTIFY_PROCESS"&
  fi

# Adding an alert prompt to let admins know that the script is in testing mode
  if [ "$TESTING_MODE" = true ]; then
    echo "Command: Alert: DEP Notify is in TESTING_MODE. Script will not run Policies or other commands that make change to this computer."  >> "$DEP_NOTIFY_LOG"
  fi

# Adding nice text and a brief pause for prettiness
  echo "Status: $INITAL_START_STATUS" >> "$DEP_NOTIFY_LOG"
  sleep 5

# Setting the status bar
  # Counter is for making the determinate look nice. Starts at one and adds
  # more based on EULA, register, or other options.
    ADDITIONAL_OPTIONS_COUNTER=1
    if [ "$EULA_ENABLED" = true ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
    if [ "$REGISTRATION_ENABLED" = true ]; then ((ADDITIONAL_OPTIONS_COUNTER++))
      if [ "$REG_TEXT_LABEL_1" != "" ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
      if [ "$REG_TEXT_LABEL_2" != "" ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
      if [ "$REG_POPUP_LABEL_1" != "" ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
      if [ "$REG_POPUP_LABEL_2" != "" ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
      if [ "$REG_POPUP_LABEL_3" != "" ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
      if [ "$REG_POPUP_LABEL_4" != "" ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi
    fi

  # Checking policy array and adding the count from the additional options above.
    ARRAY_LENGTH="$((${#POLICY_ARRAY[@]}+ADDITIONAL_OPTIONS_COUNTER))"
    echo "Command: Determinate: $ARRAY_LENGTH" >> "$DEP_NOTIFY_LOG"

# EULA Window Display Logic
  if [ "$EULA_ENABLED" = true ]; then
    echo "Status: $EULA_STATUS" >> "$DEP_NOTIFY_LOG"
    echo "Command: ContinueButtonEULA: $EULA_BUTTON" >> "$DEP_NOTIFY_LOG"
    while [ ! -f "$DEP_NOTIFY_EULA_DONE" ]; do
      echo "$(date "+%a %h %d %H:%M:%S"): Waiting for user to accept EULA." >> "$DEP_NOTIFY_DEBUG"
      sleep 1
    done
  fi

# Registration Window Display Logic
  if [ "$REGISTRATION_ENABLED" = true ]; then
    echo "Status: $REGISTRATION_STATUS" >> "$DEP_NOTIFY_LOG"
    echo "Command: ContinueButtonRegister: $REGISTRATION_BUTTON" >> "$DEP_NOTIFY_LOG"
    while [ ! -f "$DEP_NOTIFY_REGISTER_DONE" ]; do
      echo "$(date "+%a %h %d %H:%M:%S"): Waiting for user to complete registration." >> "$DEP_NOTIFY_DEBUG"
      sleep 1
    done
    # Running Logic For Each Registration Box
      if [ "$REG_TEXT_LABEL_1" != "" ]; then REG_TEXT_LABEL_1_LOGIC; fi
      if [ "$REG_TEXT_LABEL_2" != "" ]; then REG_TEXT_LABEL_2_LOGIC; fi
      if [ "$REG_POPUP_LABEL_1" != "" ]; then REG_POPUP_LABEL_1_LOGIC; fi
      if [ "$REG_POPUP_LABEL_2" != "" ]; then REG_POPUP_LABEL_2_LOGIC; fi
      if [ "$REG_POPUP_LABEL_3" != "" ]; then REG_POPUP_LABEL_3_LOGIC; fi
      if [ "$REG_POPUP_LABEL_4" != "" ]; then REG_POPUP_LABEL_4_LOGIC; fi
  fi

# Loop to run policies
  for POLICY in "${POLICY_ARRAY[@]}"; do
    echo "Status: $(echo "$POLICY" | cut -d ',' -f1)" >> "$DEP_NOTIFY_LOG"
    if [ "$TESTING_MODE" = true ]; then
      sleep 10
    elif [ "$TESTING_MODE" = false ]; then
      "$JAMF_BINARY" policy "-$TRIGGER" "$(echo "$POLICY" | cut -d ',' -f2)"
    fi
  done

# Nice completion text
  echo "Status: $INSTALL_COMPLETE_TEXT" >> "$DEP_NOTIFY_LOG"

# Check to see if FileVault Deferred enablement is active
  FV_DEFERRED_STATUS=$($FDE_SETUP_BINARY status | grep "Deferred" | cut -d ' ' -f6)

  # Logic to log user out if FileVault is detected. Otherwise, app will close.
    if [ "$FV_DEFERRED_STATUS" = "active" ] && [ "$TESTING_MODE" = true ]; then
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Quit: This is typically where your FV_LOGOUT_TEXT would be displayed. However, TESTING_MODE is set to true and FileVault deferred status is on." >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: TESTING_MODE is set to true and FileVault deferred status is on. Button effect is quit instead of logout. \n \n $FV_COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButton: Test $FV_COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    elif [ "$FV_DEFERRED_STATUS" = "active" ] && [ "$TESTING_MODE" = false ]; then
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Logout: $FV_ALERT_TEXT" >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: $FV_COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButtonLogout: $FV_COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    else
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Quit: $COMPLETE_ALERT_TEXT" >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: $COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButton: $COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    fi

exit 0
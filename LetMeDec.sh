#!/bin/bash
#
###############################################################################################################################################
#
# ABOUT THIS PROGRAM
#
#	LetMeDec.sh
#	https://github.com/Headbolt/LetMeDec
#
#   This Script is designed for use in JAMF
#
#   This script was designed to enable the currently logged in user's account the ability to unlock
#   a drive that was originally encrypted with the management account using a policy from the JSS.
#	The script will prompt the user for their credentials.
#	
#	This script was designed to be run via policy at login or via Self Service.  The encryption
#	process must be fully completed before this script can be successfully executed.  
#
###############################################################################################################################################
#
# HISTORY
#
#   Version: 1.1 - 15/10/2019
#
#   - 13/01/2018 - V1.0 - Created by Headbolt
#
#   - 15/10/2019 - V1.1 - Updated by Headbolt
#                           More comprehensive error checking and notation
#
###############################################################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
###############################################################################################################################################
#
# Variables used by this script.
#
## Grab the logged in user's name
userName=$3
# Grab the Username of a FileVault Admin from JAMF variable #4 eg. username
adminName=$4
# Grab the Password of a FileVault Admin from JAMF variable #5 eg. password
adminPass=$5
# Set the name of the script for later logging
#ScriptName="append prefix here as needed - Check Login User has FV2 Enabled and Enable if Not"
ScriptName="ZZ 17 - Global Settings - Check Login User has FV2 Enabled and Enable if Not"
#
## Grab the OS version
OS=`/usr/bin/sw_vers -productVersion | awk -F. {'print $2'}`
#
###############################################################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
###############################################################################################################################################
#
# Defining Functions
#
###############################################################################################################################################
#
# Variable Check Function
#
VarCheck(){
#
# Check that the required variables are set
/bin/echo Checking that the required Variables are set
#
if [ "${adminName}" == "" ]; then
	/bin/echo "Username undefined.  Please pass the management account username in parameter 4"
	SectionEnd
	ScriptEnd
	exit 1
fi
#
if [ "${adminPass}" == "" ]; then
	echo "Password undefined.  Please pass the management account password in parameter 5"
    SectionEnd
    ScriptEnd
	exit 2
fi
#
/bin/echo Required Variables appear to be set
#
}
#

###############################################################################################################################################
#
# FileVault Check Function
#
FVcheck(){
#
## Grab Current FV2 List
userCheck=`fdesetup list | awk -F, '{print $1}'`
#
if [ "${CheckStep}" == "Second" ]
	then
    	CheckText=" "
	else
		CheckText=" already "
		/bin/echo Current FileVault User List = $userCheck
		SectionEnd
fi
#
echo $CheckStep Check Start
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
for user in $userCheck
	do
		/bin/echo Checking User Logging in $userName against $user
		if [ "${user}" == "${userName}" ]
			then
				# Outputting a Blank Line for Reporting Purposes
				/bin/echo
				/bin/echo "${userName} is${CheckText}on the FileVault 2 list."
				#
				if [ "${CheckStep}" == "Second" ]
					then
						# Outputting a Blank Line for Reporting Purposes
						/bin/echo
						#
						/bin/echo Current FileVault User List = $userCheck
						# Outputs a Blank Line For Reporting Purposes
						/bin/echo
						/bin/echo $CheckStep Check End
						#
						SectionEnd
						ScriptEnd
						exit 0
					else
						# Outputting a Blank Line for Reporting Purposes
						/bin/echo
						#
						/bin/echo Nothing To Do
						SectionEnd
						ScriptEnd
						exit 0
				fi
		fi
	done
#
# Outputs a Blank Line For Reporting Purposes
/bin/echo
/bin/echo $CheckStep Check End
#
}
#
###############################################################################################################################################
#
# Encryption Status Check Function
#
EncryptionStatus(){
#
## Check to see if the encryption process is complete
encryptCheck=`fdesetup status`
statusCheck=$(echo "${encryptCheck}" | grep "FileVault is On.")
expectedStatus="FileVault is On."
if [ "${statusCheck}" != "${expectedStatus}" ]
    then
    	/bin/echo "The encryption process has not completed, unable to add user at this time."
    	/bin/echo "${encryptCheck}"
		SectionEnd
		ScriptEnd
    	exit 4
    else
       	/bin/echo "The encryption process appears completed"
    	/bin/echo "${encryptCheck}"
fi
#
}
#
###############################################################################################################################################
#
# Add User Function
#
AddUser(){
#
## Get the logged in user's password via a prompt
/bin/echo "Prompting ${userName} for their login password."
userPass="$(osascript -e 'Tell application "System Events" to display dialog "Your account cannot unlock this Computer after a reboot.\nPlease enter your login password to enable this." default answer "" with title "Startup Password" with text buttons {"Ok"} default button 1 with hidden answer' -e 'text returned of result' 2>/dev/null)"
/bin/echo "Adding User "${userName}" to FileVault 2 list."
/bin/echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>Username</key><string>'$adminName'</string><key>Password</key><string>'$adminPass'</string><key>AdditionalUsers</key><array><dict><key>Username</key><string>'$userName'</string><key>Password</key><string>'$userPass'</string></dict></array></dict></plist>' | fdesetup add -inputplist
#
}
#
###############################################################################################################################################
#
# Section End Function
#
SectionEnd(){
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
# Outputting a Dotted Line for Reporting Purposes
/bin/echo  -----------------------------------------------
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
}
#
###############################################################################################################################################
#
# Script End Function
#
ScriptEnd(){
#
# Outputting a Blank Line for Reporting Purposes
#/bin/echo
#
/bin/echo Ending Script '"'$ScriptName'"'
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
# Outputting a Dotted Line for Reporting Purposes
/bin/echo  -----------------------------------------------
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
#
}
#
###############################################################################################################################################
#
# End Of Function Definition
#
###############################################################################################################################################
# 
# Begin Processing
#
####################################################################################################
#
# Outputting a Blank Line for Reporting Purposes
/bin/echo
SectionEnd
#
VarCheck
SectionEnd
#
/bin/echo OS Major Version is 10.${OS}
#
/bin/echo User Logging In = $userName
#
CheckStep="First"
FVcheck
SectionEnd
#
EncryptionStatus
SectionEnd
#
AddUser
SectionEnd
#
CheckStep="Second"
FVcheck
SectionEnd
#
/bin/echo "Failed to add user to FileVault 2 list."
# Outputs a Blank Line For Reporting Purposes
/bin/echo
/bin/echo "Currently enabled users:"
/bin/echo "${userCheck}"
#
SectionEnd
ScriptEnd
exit 6
#
ScriptEnd

	#!/bin/bash

	# This script is designed to use the Jamf Pro API to identify the individual 
	# IDs of the scripts stored on a Jamf Pro server then do the following:
	#
	# 1. Download the script as XML
	# 2. Identify the script name
	# 3. Extract the script contents from the downloaded XML
	# 4. Save the script to a specified directory

	# If setting up a specific user account with limited rights, here are the 
	# required API privileges for the account on the Jamf Pro server:
	#
	# Jamf Pro Server Objects:
	#
	# Scripts: Read

ScriptDownloadDirectory="/Users/Shared/Backups/scripts"

EncryptedUser="${1}"
EncryptedPass="${2}"

# URL - no trailing slash
jamfpro_url="https://example.jamfcloud.com"

# API username
jamfpro_user=$(DecryptUser.sh "${EncryptedUser}")

# API password
jamfpro_password=$(DecryptPass.sh "${EncryptedPass}")

DownloadScript(){

	# Download the script information as raw XML,
	# then format it to be readable.
	echo "Downloading scripts from $jamfpro_url..."
	FormattedScript=$(curl -su "${jamfpro_user}:${jamfpro_password}" \
	  -H "Accept: application/xml" "${jamfpro_url}/JSSResource/scripts/id/${ID}" \
	  -X GET | xmllint --format - )

	# Identify and display the script's name.
	DisplayName=$(echo "$FormattedScript" | \
	  xpath "/script/name/text()" 2>/dev/null | sed -e 's|:|(colon)|g' -e 's/\//\\/g')
	echo "Downloaded script is named: $DisplayName"

	## Save the downloaded script
	echo "Saving ${DisplayName} file to $ScriptDownloadDirectory."
	echo "$FormattedScript" > "$ScriptDownloadDirectory/${DisplayName}"

}

if [[ ! -d $ScriptDownloadDirectory ]] ; then
	mkdir -p $ScriptDownloadDirectory
fi

Script_id_list=$(curl -su "${jamfpro_user}:${jamfpro_password}" \
  -H "Accept: application/xml" "${jamfpro_url}/JSSResource/scripts" | xpath "//id" 2>/dev/null)

Script_id=$(echo "$Script_id_list" | grep -Eo "[0-9]+")

for ID in ${Script_id}; do

   DownloadScript

done

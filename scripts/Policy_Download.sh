#!/bin/bash

# This script is designed to use the Jamf Pro API to identify the individual IDs of
# the policies stored on a Jamf Pro server then do the following:
#
# 2. Download the policy as XML
# 3. Identify the policy name
# 4. Categorize the downloaded policy
# 5. Save the policy to a specified directory

# If setting up a specific user account with limited rights, here are the required API privileges
# for the account on the Jamf Pro server:
#
# Jamf Pro Server Objects:
#
# Policies: Read

PolicyDownloadDirectory="/Users/Shared/Backups/policies"

# URL - no trailing slash
jamfpro_url="https://suncorp.jamfcloud.com"

EncryptedUser="${1}"
EncryptedPass="${2}"

# API username
jamfpro_user=$(DecryptUser.sh "${EncryptedUser}")

# API password
jamfpro_password=$(DecryptPass.sh "${EncryptedPass}")


DownloadComputerPolicy(){

	# Download the policy information as raw XML,
	# then format it to be readable.
	echo "Downloading macOS computer policies from $jamfpro_url..."
	FormattedComputerPolicy=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/policies/id/${ID}" -X GET | xmllint --format - )

	# Identify and display the policy's name.
	DisplayName=$(echo "$FormattedComputerPolicy" | xpath "/policy/general/name/text()" 2>/dev/null | sed -e 's|:|(colon)|g' -e 's/\//\\/g')
	echo "Downloaded policy is named: $DisplayName"

	# Identify the policy category

	PolicyCategory=$(echo "$FormattedComputerPolicy" | xpath "/policy/general/category/name/text()" 2>/dev/null | sed -e 's|:|(colon)|g' -e 's/\//\\/g')

	# Save the downloaded policy.

	echo "Saving ${DisplayName}.xml file to $PolicyDownloadDirectory/$PolicyCategory."

	if [[ -d "$PolicyDownloadDirectory/$PolicyCategory" ]]; then
	  echo "$FormattedComputerPolicy" > "$PolicyDownloadDirectory/$PolicyCategory/${DisplayName}.xml"
	else
	  mkdir -p "$PolicyDownloadDirectory/$PolicyCategory"
	  echo "$FormattedComputerPolicy" > "$PolicyDownloadDirectory/$PolicyCategory/${DisplayName}.xml"
	fi
}

# Back up existing policy downloads and create policy download directory.

# Download latest version of all computer policies

ComputerPolicy_id_list=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/policies" | xpath "//id" 2>/dev/null)

ComputerPolicy_id=$(echo "$ComputerPolicy_id_list" | grep -Eo "[0-9]+")

for ID in ${ComputerPolicy_id}; do

   DownloadComputerPolicy

done

exit $ERROR
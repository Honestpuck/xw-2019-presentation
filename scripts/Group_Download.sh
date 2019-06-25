#!/bin/bash

# This script is designed to use the Jamf Pro API to identify the individual IDs of
# the computer groups stored on a Jamf Pro server then do the following:
#
# 1. Download the group information as XML
# 2. Remove the group membership from the downloaded XML
# 3. Identify the group name
# 4. Categorize the downloaded group as either a smart or static computer group
# 4. Save the XML to a specified directory

# If setting up a specific user account with limited rights, here are the required API privileges
# for the account on the Jamf Pro server:
#
# Jamf Pro Server Objects:
#
# Smart Computer Groups: Read
# Static Computer Groups: Read

ComputerGroupDownloadDirectory="Users/Shared/Backups/groups"

EncryptedUser="${1}"
EncryptedPass="${2}"

jamfpro_url="https://suncorp.jamfcloud.com"

# API username
jamfpro_user=$(DecryptUser.sh "${EncryptedUser}")

# API password
jamfpro_password=$(DecryptPass.sh "${EncryptedPass}")

DownloadComputerGroup(){

	# Download the group information as XML, then strip out
	# the group membership and format it.
	echo "Downloading computer group from $jamfpro_url..."
	FormattedComputerGroup=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/computergroups/id/${ID}" -X GET | tr $'\n' $'\t' | sed -E 's|<computers>.*</computers>||' |  tr $'\t' $'\n' | xmllint --format - )

	# Identify and display the group's name.
	DisplayName=$(echo "$FormattedComputerGroup" | xpath "/computer_group/name/text()" 2>/dev/null | sed -e 's|:|(colon)|g' -e 's/\//\\/g')
	echo "Downloaded computer group is named: $DisplayName"

	# Identify if it's a smart or static group.
	if [[ $(echo "$FormattedComputerGroup" | xpath "/computer_group/is_smart/text()" 2>/dev/null) == "true" ]]; then
	   GroupType="Smart"
	else
	   GroupType="Static"
	fi

	# Save the downloaded computer group.
	echo "$DisplayName is a $GroupType group."
	echo "Saving ${DisplayName}.xml file to $ComputerGroupDownloadDirectory/$GroupType Groups."
	if [[ "$GroupType" = "Smart" ]]; then
	   if [[ -d "$ComputerGroupDownloadDirectory/$GroupType Groups" ]]; then
          echo "$FormattedComputerGroup" > "$ComputerGroupDownloadDirectory/$GroupType Groups/${DisplayName}.xml"
        else
           mkdir -p "$ComputerGroupDownloadDirectory/$GroupType Groups"
           echo "$FormattedComputerGroup" > "$ComputerGroupDownloadDirectory/$GroupType Groups/${DisplayName}.xml"
        fi
    elif [[ "$GroupType" = "Static" ]]; then
        if [[ -d "$ComputerGroupDownloadDirectory/$GroupType Groups" ]]; then
          echo "$FormattedComputerGroup" > "$ComputerGroupDownloadDirectory/$GroupType Groups/${DisplayName}.xml"
        else
          mkdir -p "$ComputerGroupDownloadDirectory/$GroupType Groups"
          echo "$FormattedComputerGroup" > "$ComputerGroupDownloadDirectory/$GroupType Groups/${DisplayName}.xml"
        fi
    fi

}

ComputerGroup_id_list=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/computergroups" | xpath "//id" 2>/dev/null)

ComputerGroup_id=$(echo "$ComputerGroup_id_list" | grep -Eo "[0-9]+")

for ID in ${ComputerGroup_id}; do

   DownloadComputerGroup

done
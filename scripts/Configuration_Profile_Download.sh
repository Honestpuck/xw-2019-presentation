#!/bin/bash

# This script is designed to use the Jamf Pro API to identify the individual IDs of
# the macOS configuration profiles stored on a Jamf Pro server then download, decode
# and properly format the profiles as .mobileconfig files.

# If setting up a specific user account with limited rights, here are the required API privileges
# for the account on the Jamf Pro server:
#
# Jamf Pro Server Objects:
#
# macOS Configuration Profiles: Read

# originally written by Rich Trouton it has been changed by Tony Williams
# v1.0 05/06/2019
# Changed auth to use Bryson Tyrell's Encrypted String routines

ProfileDownloadDirectory="/Users/Shared/Backups/profiles"

EncryptedUser="${1}"
EncryptedPass="${2}"

# URL - no trailing slash
jamfpro_url="https://suncorp.jamfcloud.com"

# API username
jamfpro_user=$(DecryptUser.sh "${EncryptedUser}")

# API password
jamfpro_password=$(DecryptPass.sh "${EncryptedPass}")

DownloadProfile(){
	# Download the profile as encoded XML, then decode and format it
	# echo "Downloading Configuration Profile..."
	UnformattedProfile=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/osxconfigurationprofiles/id/${ID}" -X GET)
	FormattedProfile=$(echo $UnformattedProfile | perl -MHTML::Entities -pe 'decode_entities($_);' | xmllint --format -)

	# Identify and display the profile's name
	DisplayName=$(echo "$FormattedProfile" | awk -F'>|<' '/PayloadDisplayName/{getline; print $3; exit}')
	# echo "Downloaded profile is named: $DisplayName"

	# Save the downloaded profile
	# echo "Saving ${DisplayName}.mobileconfig file to $ProfileDownloadDirectory."
	echo "$FormattedProfile" > "$ProfileDownloadDirectory/${DisplayName}.mobileconfig"
}

profiles_id_list=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/osxconfigurationprofiles" |\
	xpath //os_x_configuration_profile/id 2>/dev/null)

profiles_id=$(echo "$profiles_id_list" | grep -Eo "[0-9]+")

for ID in ${profiles_id}; do
   DownloadProfile
done

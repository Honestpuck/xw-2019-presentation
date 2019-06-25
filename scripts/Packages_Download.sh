#!/bin/bash

# This script is designed to use the Jamf Pro API to identify the individual IDs of
# the packages stored on a Jamf Pro server then do the following:
#
# 1. Download the package details as XML
# 2. Identify the package name
# 3. Extract the  contents from the downloaded XML
# 4. Save the contents to a specified directory

# If setting up a specific user account with limited rights, here are the required API privileges
# for the account on the Jamf Pro server:
#
# Jamf Pro Server Objects:
#
# Packages: Read

PackageDownloadDirectory="/Users/Shared/Backups/packages"

EncryptedUser="${1}"
EncryptedPass="${2}"

# URL - no trailing slash
jamfpro_url="https://example.jamfcloud.com"

# API username
jamfpro_user=$(DecryptUser.sh "${EncryptedUser}")

# API password
jamfpro_password=$(DecryptPass.sh "${EncryptedPass}")

DownloadPackage(){

	# Download the package information as raw XML,
	# then format it to be readable.
	echo "Downloading packages from $jamfpro_url..."
	FormattedPackage=$(curl -su "${jamfpro_user}:${jamfpro_password}" \
	  -H "Accept: application/xml" "${jamfpro_url}/JSSResource/packages/id/${ID}" \
	  -X GET | xmllint --format - )

	# Identify and display the package's name.
	DisplayName=$(echo "$FormattedPackage" | \
	  xpath "/package/name/text()" 2>/dev/null | sed -e 's|:|(colon)|g' -e 's/\//\\/g')
	echo "Downloaded package is named: $DisplayName"

	## Save the downloaded package
	echo "Saving ${DisplayName} file to $PackageDownloadDirectory."
	echo "$FormattedPackage" > "$PackageDownloadDirectory/${DisplayName}.xml"

}

if [[ ! -d $PackageDownloadDirectory ]] ; then
	mkdir -p $PackageDownloadDirectory
fi

Package_id_list=$(curl -su "${jamfpro_user}:${jamfpro_password}" \
  -H "Accept: application/xml" "${jamfpro_url}/JSSResource/packages" | xpath "//id" 2>/dev/null)

Package_id=$(echo "$Package_id_list" | grep -Eo "[0-9]+")

for ID in ${Package_id}; do

   DownloadPackage

done


#!/bin/bash

# This script is designed to use the Jamf Pro API to identify the individual IDs of
# the computer extension attributes stored on a Jamf Pro server then do the following:
#
# 1. Download the extension attribute as XML
# 2. Identify the extension attribute name
# 3. Categorize the downloaded extension attribute
# 4. If it's a macOS or Windows extension attribute and it has a script, extract the script.
# 5. Save the extension attribute to a specified directory

# If setting up a specific user account with limited rights, here are the required API privileges
# for the account on the Jamf Pro server:
#
# Jamf Pro Server Objects:
#
# Computer Extension Attributes: Read

# directory - no trailing slash
ExtensionAttributeDownloadDirectory="/Users/Shared/Backups/attribs"

EncryptedUser="${1}"
EncryptedPass="${2}"

# URL - no trailing slash
jamfpro_url="https://example.jamfcloud.com"

# API username
jamfpro_user=$(DecryptUser.sh "${EncryptedUser}")

# API password
jamfpro_password=$(DecryptPass.sh "${EncryptedPass}")

DownloadComputerExtensionAttribute(){

	# Download the extension attribute information as raw XML,
	# then format it to be readable.
	ComputerExtensionAttribute=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/computerextensionattributes/id/${ID}")
	FormattedComputerExtensionAttribute=$(echo "$ComputerExtensionAttribute" | xmllint --format -)

	# Identify and display the extension attribute's name.
	DisplayName=$(echo "$FormattedComputerExtensionAttribute" | xpath "/computer_extension_attribute/name/text()" 2>/dev/null | sed -e 's|:|(colon)|g' -e 's/\//\\/g')
	echo "Downloaded extension attribute is named: \"$DisplayName\""

	# Identify the EA type.
	EAType=$(echo "$FormattedComputerExtensionAttribute" | xpath "/computer_extension_attribute/data_type/text()" 2>/dev/null)
 	echo "\"$DisplayName\" is a \"$EAType\" extension attribute."

	# get the number of input_type nodes. In some cases an EA may contain scripts for macOS and Windows. So if we find
	# more than one input_tpye node, we just use the one for macOS
    EAInputTypeNodeCount=$(echo "$FormattedComputerExtensionAttribute" | xpath "count(/computer_extension_attribute/input_type/type)" 2>/dev/null)

    while [[ $EAInputTypeNodeCount -gt 0 ]]; do

    	EAInputType=$(echo "$FormattedComputerExtensionAttribute" | xpath "/computer_extension_attribute/input_type[$EAInputTypeNodeCount]/type/text()" 2>/dev/null)
    	FinalAttribute=""
    	FileName=""

		if [[ -n "$EAInputType" ]]; then

			echo "\"$DisplayName\" is an extension attribute of type \"$EAInputType\"."

			TargetDirectory="$ExtensionAttributeDownloadDirectory/$EAType/$EAInputType"

			if [[ "$EAInputType" = "script" ]]; then

				# get the platform
				ScriptPlatform=$(echo "$FormattedComputerExtensionAttribute" | xpath "/computer_extension_attribute/input_type[$EAInputTypeNodeCount]/platform/text()" 2>/dev/null)

				if [[ -n "$ScriptPlatform" ]]; then
					echo "\"$DisplayName\" runs on $ScriptPlatform."
					TargetDirectory="$TargetDirectory/$ScriptPlatform"

					if [[ "$ScriptPlatform" = "Mac" ]]; then
						FileName=$(echo "$DisplayName" | sed 's/[:/[:cntrl:]]/_/g')
						FileName="${FileName}.sh"
					elif [[ "$ScriptPlatform" = "Windows" ]]; then
						FileName=$(echo "$DisplayName" | sed 's/[.<>:"/\|?*[:cntrl:]]/_/g')
						FileName="${FileName}.wsf"
					fi
				fi

				FinalAttribute=$(echo "$FormattedComputerExtensionAttribute" | xpath "/computer_extension_attribute/input_type[$EAInputTypeNodeCount]/script/text()" 2>/dev/null | perl -MHTML::Entities -pe 'decode_entities($_);')
			else
				FileName="${DisplayName}.xml"
				FinalAttribute="$FormattedComputerExtensionAttribute"
			fi

			# create the directory if needed
			if [[ ! -d "$TargetDirectory" ]]; then
			  	mkdir -p "$TargetDirectory"
			fi

			echo "Saving \"$FileName\" file to $TargetDirectory."
			echo "$FinalAttribute" | perl -MHTML::Entities -pe 'decode_entities($_);' > "$TargetDirectory/$FileName"
		else
			echo "Error! Unable to determine the attribute's input type"
		fi

		((EAInputTypeNodeCount--))
	done

	echo
}

ComputerExtensionAttribute_id_list=$(curl -su "${jamfpro_user}:${jamfpro_password}" -H "Accept: application/xml" "${jamfpro_url}/JSSResource/computerextensionattributes" | xpath "//id" 2>/dev/null)

if [[ -n "$ComputerExtensionAttribute_id_list" ]]; then

	echo "Downloading extension attributes from $jamfpro_url..."
	ComputerExtensionAttribute_id=$(echo "$ComputerExtensionAttribute_id_list" | grep -Eo "[0-9]+")

	for ID in ${ComputerExtensionAttribute_id}; do
	   DownloadComputerExtensionAttribute
	done

else
	echo "ERROR! Unable to get extension attribute list"
fi

exit 0